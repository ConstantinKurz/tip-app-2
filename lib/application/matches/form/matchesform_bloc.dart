import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/match_failures.dart';
import 'package:flutter_web/domain/entities/id.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:meta/meta.dart';

part 'matchesform_event.dart';
part 'matchesform_state.dart';

class MatchesformBloc extends Bloc<MatchesformEvent, MatchesformState> {
  final MatchRepository matchesRepository;
  MatchesformBloc({required this.matchesRepository})
      : super(MatchesformState(
            isSubmitting: false,
            showValidationMessages: false,
            matchFailureOrSuccessOption: none())) {
    on<CreateMatchEvent>((event, emit) async {
      if (event.homeTeamId == null ||
          event.guestTeamId == null ||
          event.matchDate == null ||
          event.matchDay == null) {
        // Handle the case where one or more fields are null
        emit(MatchesformState(
          isSubmitting: false,
          showValidationMessages: true,
        ));
      } else {
        emit(state.copyWith(isSubmitting: true, showValidationMessages: false));
        CustomMatch match = CustomMatch.empty().copyWith(
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
  }
}
