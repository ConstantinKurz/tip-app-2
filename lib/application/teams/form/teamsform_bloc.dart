import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:flutter_web/domain/usecases/recalculate_match_tips_usecase.dart';
import 'package:meta/meta.dart';

part 'teamsform_event.dart';
part 'teamsform_state.dart';

class TeamsformBloc extends Bloc<TeamsformEvent, TeamsformState> {
  final TeamRepository teamRepository;
  final MatchRepository matchRepository;
  final RecalculateMatchTipsUseCase recalculateMatchTipsUseCase;

  TeamsformBloc({
    required this.teamRepository,
    required this.matchRepository,
    required this.recalculateMatchTipsUseCase,
  }) : super(TeamsformInitialState()) {
    on<TeamFormCreateEvent>(_onCreateTeam);
    on<TeamFormUpdateEvent>(_onUpdateTeam);
    on<TeamFormFieldUpdatedEvent>(_onFieldUpdated);
    on<TeamFormDeleteEvent>(_onDeleteTeam);
  }

  Future<void> _onCreateTeam(
    TeamFormCreateEvent event,
    Emitter<TeamsformState> emit,
  ) async {
    if (event.team == null) {
      emit(state.copyWith(isSubmitting: false, showValidationMessages: true));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    final failureOrSuccess = await teamRepository.createTeam(event.team!);

    emit(state.copyWith(
      isSubmitting: false,
      teamFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
  }

  Future<void> _onUpdateTeam(
    TeamFormUpdateEvent event,
    Emitter<TeamsformState> emit,
  ) async {
    if (event.team == null) {
      emit(state.copyWith(isSubmitting: false, showValidationMessages: true));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    // Lade altes Team um Champion-Änderung zu erkennen
    final oldTeamResult = await teamRepository.getById(event.team!.id);
    final bool oldChampion = oldTeamResult.fold(
      (_) => false,
      (oldTeam) => oldTeam.champion,
    );
    final bool newChampion = event.team!.champion;
    final bool championChanged = oldChampion != newChampion;

    final failureOrSuccess = await teamRepository.updateTeam(event.team!);

    // 🏆 Bei Champion-Änderung: Finale neu berechnen!
    if (championChanged) {
      await _recalculateFinalMatch();
    }

    emit(state.copyWith(
      isSubmitting: false,
      teamFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
  }

  /// Berechnet das Finale-Match neu (für Champion-Punkte)
  Future<void> _recalculateFinalMatch() async {
    debugPrint('🏆 Champion-Flag geändert - Berechne Finale neu...');
    
    // Cache leeren damit neue Champion-Daten geladen werden
    recalculateMatchTipsUseCase.clearCache();
    
    // Finde das Finale-Match (zeitlich letztes matchDay 8)
    final allMatchesResult = await matchRepository.getAllMatches();
    await allMatchesResult.fold(
      (failure) async {
        debugPrint('❌ Fehler beim Laden der Matches: $failure');
      },
      (allMatches) async {
        // WICHTIG: Erst ALLE matchDay-8-Spiele sortieren, DANN prüfen ob Finale Result hat
        // Sonst würde Spiel um Platz 3 als Finale behandelt wenn es früher Result bekommt
        final matchDay8Matches = allMatches
            .where((m) => m.matchDay == 8)
            .toList()
          ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

        // Das zeitlich letzte Spiel ist das echte Finale
        final trueFinale = matchDay8Matches.isNotEmpty ? matchDay8Matches.first : null;
        
        if (trueFinale != null && trueFinale.hasResult) {
          final finalMatch = trueFinale;
          debugPrint('🏆 Berechne Finale neu: ${finalMatch.id}');
          
          await recalculateMatchTipsUseCase(match: finalMatch);
          await recalculateMatchTipsUseCase.updateAllUserRankings();
          
          debugPrint('✅ Finale und Rankings neu berechnet');
        } else {
          debugPrint('ℹ️ Kein Finale-Match mit Ergebnis gefunden');
        }
      },
    );
  }

  void _onFieldUpdated(
    TeamFormFieldUpdatedEvent event,
    Emitter<TeamsformState> emit,
  ) {
    emit(state.copyWith(
      id: event.id ?? state.id,
      name: event.name ?? state.name,
      flagCode: event.flagCode ?? state.flagCode,
      winPoints: event.winPoints ?? state.winPoints,
      champion: event.champion ?? state.champion,
    ));
  }

  Future<void> _onDeleteTeam(
    TeamFormDeleteEvent event,
    Emitter<TeamsformState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      showValidationMessages: false,
      teamFailureOrSuccessOption: none(),
    ));

    final failureOrSuccess = await teamRepository.deleteTeamById(event.id);

    emit(state.copyWith(
      isSubmitting: false,
      teamFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
  }
}
