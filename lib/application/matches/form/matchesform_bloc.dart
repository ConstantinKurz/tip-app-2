import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/core/failures/match_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:meta/meta.dart';

part 'matchesform_event.dart';
part 'matchesform_state.dart';

class MatchesformBloc extends Bloc<MatchesformEvent, MatchesformState> {
  final MatchRepository matchesRepository;
  MatchesformBloc({required this.matchesRepository})
      : super(MatchesFromInitialState()) {
    on<CreateMatchEvent>((event, emit) async {
      if (event.id == null ||
          event.homeTeamId == null ||
          event.guestTeamId == null ||
          event.matchDate == null ||
          event.matchDay == null) {
        // Handle the case where one or more fields are null
        emit(state.copyWith(isSubmitting: false, showValidationMessages: true));
      } else {
        emit(state.copyWith(isSubmitting: true, showValidationMessages: false));
        CustomMatch match = CustomMatch.empty().copyWith(
            id: event.id,
            homeTeamId: event.homeTeamId,
            guestTeamId: event.guestTeamId,
            matchDate: event.matchDate,
            matchDay: event.matchDay);
        final failureOrSuccess = await matchesRepository.createMatch(match);

        emit(state.copyWith(
          isSubmitting: false,
          matchFailureOrSuccessOption: optionOf(failureOrSuccess),
        ));
      }
    });

    on<MatchFormUpdateEvent>((event, emit) async {
      print(event);
      print(state.toString());
      if (event.match != null) {
        emit(state.copyWith(isSubmitting: true, showValidationMessages: false));
        final failureOrSuccess =
            await matchesRepository.updateMatch(event.match!);
        print('Update Failure or Success: $failureOrSuccess');
        print("Formupdate event state ${state.copyWith(
          isSubmitting: false,
          matchFailureOrSuccessOption: optionOf(failureOrSuccess),
        )}");
        emit(state.copyWith(
          isSubmitting: false,
          matchFailureOrSuccessOption: optionOf(failureOrSuccess),
        ));
      } else {
        emit(state.copyWith(isSubmitting: false, showValidationMessages: true));
      }
    });

    on<MatchFormFieldUpdatedEvent>((event, emit) {
      emit(state.copyWith(
          homeTeamId: event.homeTeamId ?? state.homeTeamId,
          guestTeamId: event.guestTeamId ?? state.guestTeamId,
          matchDate: event.matchDate ?? state.matchDate,
          matchTime: event.matchTime ?? state.matchTime,
          matchDay: event.matchDay ?? state.matchDay,
          homeScore: event.homeTeamScore ?? state.homeScore,
          guestScore: event.guestTeamScore ?? state.guestScore));
    });

    on<MatchFormDeleteEvent>((event, emit) async {
      emit(state.copyWith(
          isSubmitting: true,
          showValidationMessages: false,
          matchFailureOrSuccessOption: none()));

      final failureOrSuccess =
          await matchesRepository.deleteMatchById(event.id);

      emit(state.copyWith(
        isSubmitting: false,
        matchFailureOrSuccessOption: optionOf(failureOrSuccess),
      ));
    });
  }
}
