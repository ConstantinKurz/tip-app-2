import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:meta/meta.dart';

part 'teamsform_event.dart';
part 'teamsform_state.dart';

class TeamsformBloc extends Bloc<TeamsformEvent, TeamsformState> {
  final TeamRepository teamRepository;

  TeamsformBloc({required this.teamRepository})
      : super(TeamsformInitialState()) {
    on<TeamFormCreateEvent>((event, emit) async {
      if (event.team == null) {
        emit(state.copyWith(isSubmitting: false, showValidationMessages: true));
      } else {
        emit(state.copyWith(isSubmitting: true, showValidationMessages: false));
        final failureOrSuccess = await teamRepository.createTeam(event.team!);
        emit(state.copyWith(
          isSubmitting: false,
          teamFailureOrSuccessOption: optionOf(failureOrSuccess),
        ));
      }
    });

    on<TeamFormUpdateEvent>((event, emit) async {
      if (event.team != null) {
        emit(state.copyWith(isSubmitting: true, showValidationMessages: false));
        final failureOrSuccess = await teamRepository.updateTeam(event.team!);
        print('Update Failure or Success: $failureOrSuccess');
        print("Formupdate event state ${state.copyWith(
          isSubmitting: false,
          teamFailureOrSuccessOption: optionOf(failureOrSuccess),
        )}");
        emit(state.copyWith(
          isSubmitting: false,
          teamFailureOrSuccessOption: optionOf(failureOrSuccess),
        ));
      } else {
        emit(state.copyWith(isSubmitting: false, showValidationMessages: true));
      }
    });

    on<TeamFormFieldUpdatedEvent>((event, emit) async {
      emit(state.copyWith(
          id: event.id ?? state.id,
          name: event.name ?? state.name,
          flagCode: event.flagCode ?? state.flagCode,
          winPoints: event.winPoints ?? state.winPoints,
          champion: event.champion ?? state.champion));
    });

    on<TeamFormDeleteEvent>((event, emit) async {
      emit(state.copyWith(
          isSubmitting: true,
          showValidationMessages: false,
          teamFailureOrSuccessOption: none()));

      final failureOrSuccess = await teamRepository.deleteTeam(event.id);

      emit(state.copyWith(
        isSubmitting: false,
        teamFailureOrSuccessOption: optionOf(failureOrSuccess),
      ));
    });
  }
}
