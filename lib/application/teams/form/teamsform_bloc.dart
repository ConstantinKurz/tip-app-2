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

  TeamsformBloc({required this.teamRepository}) : super(TeamsformInitialState()) {
    on<TeamFormCreateTeamEvent>((event, emit) async {
      if (event.team == null){
        emit(state.copyWith(isSubmitting: false, showValidationMessages: true));
      }
      else {
      emit(state.copyWith(isSubmitting: true, showValidationMessages: false));
      final failureOrSuccess = await teamRepository.create(event.team!);
        emit(state.copyWith(
          isSubmitting: false,
          teamFailureOrSuccessOption: optionOf(failureOrSuccess),
        ));
      }
    });


    // on<DeleteTeamEvent>((event, emit) async {
    //   final failureOrSuccess = await teamRepository.delete(event.team);
    //   failureOrSuccess.fold(
    //     (failure) => emit(TeamFailureState(teamFailure: failure)),
    //     (_) => ()
    //   );
    // });
  }
}
