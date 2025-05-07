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