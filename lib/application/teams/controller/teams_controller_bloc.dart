import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:meta/meta.dart';

part 'teams_controller_event.dart';
part 'teams_controller_state.dart';

class TeamsControllerBloc
    extends Bloc<TeamsControllerEvent, TeamsControllerState> {
  final TeamRepository teamRepository;
  StreamSubscription<Either<TeamFailure, List<Team>>>? _teamStreamSubscription;

  TeamsControllerBloc({required this.teamRepository})
      : super(TeamsControllerInitial()) {
    on<TeamsControllerAllEvent>(_onTeamsControllerAllEvent);
    on<TeamsControllerUpdatedEvent>(_onTeamsControllerUpdatedEvent);
  }

  Future<void> _onTeamsControllerAllEvent(
    TeamsControllerAllEvent event,
    Emitter<TeamsControllerState> emit,
  ) async {
    emit(TeamsControllerLoading());

    // Falls schon ein Stream aktiv ist, beenden
    await _teamStreamSubscription?.cancel();

    // Repository-Stream starten
    _teamStreamSubscription = teamRepository.watchAllTeams().listen(
      (failureOrTeams) =>
          add(TeamsControllerUpdatedEvent(failureOrTeams: failureOrTeams)),
      onError: (_) {
        // Sollte durch Fehler-Mapping im Repository selten passieren
        emit(TeamsControllerFailureState(teamFailure: UnexpectedFailure()));
      },
    );
  }

  void _onTeamsControllerUpdatedEvent(
    TeamsControllerUpdatedEvent event,
    Emitter<TeamsControllerState> emit,
  ) {
    event.failureOrTeams.fold(
      (failure) => emit(TeamsControllerFailureState(teamFailure: failure)),
      (teams) => emit(TeamsControllerLoaded(teams: teams)),
    );
  }

  @override
  Future<void> close() {
    _teamStreamSubscription?.cancel();
    return super.close();
  }
}
