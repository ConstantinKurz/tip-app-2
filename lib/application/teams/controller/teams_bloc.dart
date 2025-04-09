import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:meta/meta.dart';

part 'teams_event.dart';
part 'teams_state.dart';

class TeamsBloc extends Bloc<TeamEvent, TeamsState> {
  final TeamRepository teamRepository;
    StreamSubscription<Either<TeamFailure, List<Team>>>? _teamStreamSubscription;

  TeamsBloc({required this.teamRepository}) : super(TeamInitial()) {
    on<TeamsAllEvent>((event, emit) async {
      emit(TeamsLoading());
      await _teamStreamSubscription?.cancel();
      teamRepository.watchAllTeams().listen((failureOrMatches) {
        add(TeamsUpdatedEvent(failureOrTeams: failureOrMatches));
      });
    });

    on<CreateTeamEvent>((event, emit) async {
      emit(TeamsLoading());
      final failureOrSuccess = await teamRepository.create(event.team);
      failureOrSuccess.fold(
        (failure) => emit(TeamFailureState(teamFailure: failure)),
        (_) => (),
      );
    });

    on<TeamsUpdatedEvent>((event, emit) {
      print("teams updated");
      event.failureOrTeams.fold(
        (failure) => emit(TeamFailureState(teamFailure: failure)),
        (teams) => emit(TeamsLoaded(teams: teams))
      );
    });

    on<DeleteTeamEvent>((event, emit) async {
      emit(TeamsLoading());
      final failureOrSuccess = await teamRepository.delete(event.team);
      failureOrSuccess.fold(
        (failure) => emit(TeamFailureState(teamFailure: failure)),
        (_) => ()
      );
    });
  }
}
