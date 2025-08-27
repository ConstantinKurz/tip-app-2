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

    final failureOrSuccess = await teamRepository.updateTeam(event.team!);

    emit(state.copyWith(
      isSubmitting: false,
      teamFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
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
