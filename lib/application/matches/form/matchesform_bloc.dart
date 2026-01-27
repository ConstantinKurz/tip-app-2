import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/core/failures/match_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/usecases/recalculate_match_tips_usecase.dart';

part 'matchesform_event.dart';
part 'matchesform_state.dart';

class MatchesformBloc extends Bloc<MatchesformEvent, MatchesformState> {
  final MatchRepository matchesRepository;
  final RecalculateMatchTipsUseCase recalculateMatchTipsUseCase;

  MatchesformBloc({
    required this.matchesRepository,
    required this.recalculateMatchTipsUseCase,
  }) : super(MatchesFromInitialState()) {
    on<CreateMatchEvent>(_onCreateMatch);
    on<MatchFormUpdateEvent>(_onUpdateMatch);
    on<MatchFormFieldUpdatedEvent>(_onFieldUpdated);
    on<MatchFormDeleteEvent>(_onDeleteMatch);
  }

  Future<void> _onCreateMatch(
    CreateMatchEvent event,
    Emitter<MatchesformState> emit,
  ) async {
    // Validierungs-Check
    if (event.id == null ||
        event.homeTeamId == null ||
        event.guestTeamId == null ||
        event.matchDate == null ||
        event.matchDay == null) {
      emit(state.copyWith(
        isSubmitting: false,
        showValidationMessages: true,
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    final match = CustomMatch.empty().copyWith(
      id: event.id,
      homeTeamId: event.homeTeamId,
      guestTeamId: event.guestTeamId,
      matchDate: event.matchDate,
      matchDay: event.matchDay,
    );

    final failureOrSuccess = await matchesRepository.createMatch(match);

    emit(state.copyWith(
      isSubmitting: false,
      matchFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
  }

  Future<void> _onUpdateMatch(
    MatchFormUpdateEvent event,
    Emitter<MatchesformState> emit,
  ) async {
    if (event.match == null) {
      emit(state.copyWith(
        isSubmitting: false,
        showValidationMessages: true,
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    final failureOrSuccess =
        await matchesRepository.updateMatch(event.match!);

    await failureOrSuccess.fold(
      (failure) async {
        emit(state.copyWith(
          isSubmitting: false,
          matchFailureOrSuccessOption: some(left(failure)),
        ));
      },
      (_) async {
        // Wenn Match Ergebnis hat → Punkte + User-Score neuberechnen
        if (event.match!.hasResult) {
          await recalculateMatchTipsUseCase(match: event.match!);
        }

        emit(state.copyWith(
          isSubmitting: false,
          matchFailureOrSuccessOption: optionOf(failureOrSuccess),
        ));
      },
    );
  }

  void _onFieldUpdated(
    MatchFormFieldUpdatedEvent event,
    Emitter<MatchesformState> emit,
  ) {
    emit(state.copyWith(
      homeTeamId: event.homeTeamId ?? state.homeTeamId,
      guestTeamId: event.guestTeamId ?? state.guestTeamId,
      matchDate: event.matchDate ?? state.matchDate,
      matchTime: event.matchTime ?? state.matchTime,
      matchDay: event.matchDay ?? state.matchDay,
      homeScore: event.homeTeamScore ?? state.homeScore,
      guestScore: event.guestTeamScore ?? state.guestScore,
    ));
  }

  Future<void> _onDeleteMatch(
    MatchFormDeleteEvent event,
    Emitter<MatchesformState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      showValidationMessages: false,
      matchFailureOrSuccessOption: none(),
    ));

    final failureOrSuccess =
        await matchesRepository.deleteMatchById(event.id);

    emit(state.copyWith(
      isSubmitting: false,
      matchFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
  }
}
