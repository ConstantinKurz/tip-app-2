part of 'teams_controller_bloc.dart';

abstract class TeamsControllerEvent {}

final class TeamsControllerAllEvent extends TeamsControllerEvent {}

final class TeamsControllerLoadingEvent extends TeamsControllerEvent {}

final class TeamsControllerUpdatedEvent extends TeamsControllerEvent {
    final Either<TeamFailure, List<Team>> failureOrTeams;
  TeamsControllerUpdatedEvent({
    required this.failureOrTeams,
  });
}