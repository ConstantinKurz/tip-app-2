part of 'teams_bloc.dart';

abstract class TeamEvent {}

final class TeamsAllEvent extends TeamEvent {}

final class TeamsLoadingEvent extends TeamEvent {}

final class TeamsUpdatedEvent extends TeamEvent {
    final Either<TeamFailure, List<Team>> failureOrTeams;
  TeamsUpdatedEvent({
    required this.failureOrTeams,
  });
}

class CreateTeamEvent extends TeamEvent {
  final Team team;

  CreateTeamEvent({required this.team});
}

class UpdateTeamEvent extends TeamEvent {
  final Team team;

  UpdateTeamEvent({required this.team});
}

class DeleteTeamEvent extends TeamEvent {
  final Team team;

  DeleteTeamEvent({required this.team});
}
