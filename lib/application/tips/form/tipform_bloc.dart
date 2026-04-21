import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match_day_statistics.dart';
import 'package:flutter_web/domain/entities/match_phase.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/usecases/validate_joker_usage_update_stat_usecase.dart';
import '../../../domain/entities/tip.dart';

part 'tipform_event.dart';
part 'tipform_state.dart';

class TipFormBloc extends Bloc<TipFormEvent, TipFormState> {
  final TipRepository tipRepository;
  final ValidateJokerUsageUpdateStatUseCase validateJokerUseCase;
  // Stream entfernt - wir nutzen externe Daten vom TipControllerBloc
  // StreamSubscription<Either<TipFailure, List<Tip>>>? _userTipsSubscription;

  TipFormBloc({
    required this.tipRepository,
    required this.validateJokerUseCase,
  }) : super(const TipFormInitialState()) {
    on<TipFormInitializedEvent>(_onInitialized);
    on<TipFormFieldUpdatedEvent>(_onFieldUpdated);
    on<TipFormStreamUpdatedEvent>(_onStreamUpdated);
    on<TipFormExternalUpdateEvent>(_onExternalUpdate);
    on<TipFormDeleteEvent>(_onDeleteTip);
  }

  /// Externe Updates vom TipControllerBloc verarbeiten
  /// Vermeidet separate Firebase-Streams pro TipCard
  Future<void> _onExternalUpdate(
    TipFormExternalUpdateEvent event,
    Emitter<TipFormState> emit,
  ) async {
    // Nur updaten wenn es für dieses Match relevant ist
    if (state.matchId.isNotEmpty && state.matchId != event.matchId) return;

    emit(state.copyWith(
      matchId: event.matchId,
      matchDay: event.matchDay,
      tipHome: event.tipHome,
      clearTipHome: event.tipHome == null,
      tipGuest: event.tipGuest,
      clearTipGuest: event.tipGuest == null,
      joker: event.joker,
      isLoading: false,
      isTipLimitReached: event.isTipLimitReached,
    ));
  }

  Future<void> _onInitialized(
    TipFormInitializedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    // Nur State initialisieren - kein eigener Stream mehr
    // Der TipControllerBloc hat bereits alle Tips geladen
    emit(state.copyWith(
      userId: event.userId,
      matchId: event.matchId,
      matchDay: event.matchDay,
      isLoading: true,
    ));
  }

  Future<void> _onFieldUpdated(
    TipFormFieldUpdatedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    // Wenn eines der Felder null ist, aktualisiere nur den State ohne zu speichern
    if (event.tipHome == null || event.tipGuest == null) {
      emit(state.copyWith(
        isSubmitting: false,
        showValidationMessages: false,
        tipHome: event.tipHome,
        clearTipHome: event.tipHome == null,
        tipGuest: event.tipGuest,
        clearTipGuest: event.tipGuest == null,
        joker: state.joker,
        failureOrSuccessOption: none(), // Kein Fehler, nur leere Eingabe
        isLoading: false,
      ));
      return;
    }

    emit(state.copyWith(
      isSubmitting: true,
      failureOrSuccessOption: none(),
      isLoading: false
    ));

    // ✅ NEU: Tipp-Limit-Validierung für Vorrunde (nur bei NEUEM Tipp)
    final isNewTip = state.tipHome == null && state.tipGuest == null;
    final phase = MatchPhase.fromMatchDay(event.matchDay);
    
    if (isNewTip && phase.hasTipLimit) {
      final matchDaysForPhase = phase == MatchPhase.groupStage ? [1, 2, 3] : [event.matchDay];
      final tippedGamesResult = await tipRepository.getTippedGamesInMatchDays(
        userId: event.userId,
        matchDays: matchDaysForPhase,
      );
      
      final tipLimitReached = tippedGamesResult.fold(
        (_) => false,
        (tippedGames) => tippedGames >= phase.maxTips!,
      );
      
      if (tipLimitReached) {
        final tippedGames = tippedGamesResult.getOrElse(() => 0);
        emit(state.copyWith(
          isSubmitting: false,
          showValidationMessages: true,
          isTipLimitReached: true,
          failureOrSuccessOption: some(
            left(TipLimitReachedFailure(
              used: tippedGames,
              limit: phase.maxTips!,
              matchDay: event.matchDay,
            )),
          ),
        ));
        return;
      }
    }

    // Joker-Validierung NUR prüfen wenn Joker NEU gesetzt wird
    // (nicht wenn er bereits gesetzt war und wir nur den Tipp aktualisieren)
    final isSettingNewJoker = (event.joker ?? false) && !state.joker;
    
    if (isSettingNewJoker) {
      final validationResult = await validateJokerUseCase(
        userId: event.userId,
        matchDay: event.matchDay,
      );

      final isValid = validationResult.fold(
        (_) => false,
        (result) => result.isJokerAvailable,
      );

      if (!isValid) {
        final stats = validationResult.getOrElse(
          () => MatchDayStatistics(
            matchDay: event.matchDay,
            tippedGames: 0,
            totalGames: 0,
            jokersUsed: 0,
            jokersAvailable: 0,
          ),
        );

        emit(state.copyWith(
          isSubmitting: false,
          showValidationMessages: true,
          failureOrSuccessOption: some(
            left(JokerLimitReachedFailure(
              used: stats.jokersUsed,
              limit: stats.jokersAvailable,
              matchDay: event.matchDay,
            )),
          ),
        ));
        return;
      }
    }

    // Erstelle oder aktualisiere Tip
    final tip = Tip(
      id: "${event.userId}_${event.matchId}",
      userId: event.userId,
      matchId: event.matchId,
      tipDate: DateTime.now(),
      tipHome: event.tipHome,
      tipGuest: event.tipGuest,
      joker: event.joker ?? false,
      points:
          null, // ✅ Points werden später durch die RecalculateMatchTipsUseCase berechnet
    );

    final result = await tipRepository.create(tip);

    emit(state.copyWith(
      isSubmitting: false,
      tipHome: event.tipHome,
      tipGuest: event.tipGuest,
      joker: event.joker,
      showValidationMessages: true,
      failureOrSuccessOption: some(result),
    ));
  }

  Future<void> _onStreamUpdated(
    TipFormStreamUpdatedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    emit(state.copyWith(
      userId: event.userId,
      matchId: event.matchId,
      matchDay: event.matchDay,
      tipHome: event.tipHome,
      clearTipHome: event.tipHome == null,
      tipGuest: event.tipGuest,
      clearTipGuest: event.tipGuest == null,
      joker: event.joker,
      isLoading: false,
    ));
  }

  /// Handler für das Löschen eines Tipps
  Future<void> _onDeleteTip(
    TipFormDeleteEvent event,
    Emitter<TipFormState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      failureOrSuccessOption: none(),
    ));

    final result = await tipRepository.deleteTipById(event.tipId);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          showValidationMessages: true,
          failureOrSuccessOption: some(left(failure)),
        ));
      },
      (_) {
        // Erfolg: State zurücksetzen (Tipp gelöscht)
        emit(state.copyWith(
          isSubmitting: false,
          showValidationMessages: false,
          tipHome: null,
          clearTipHome: true,
          tipGuest: null,
          clearTipGuest: true,
          joker: false,
          isTipLimitReached: false,
          failureOrSuccessOption: some(right(unit)),
        ));
      },
    );
  }

  @override
  Future<void> close() async {
    // Stream wurde entfernt - nichts zu canceln
    return super.close();
  }
}
