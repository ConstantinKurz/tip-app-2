part of 'teams_controller_bloc.dart';

@immutable
sealed class TeamsControllerState {
  const TeamsControllerState();
}

final class TeamsControllerInitial extends TeamsControllerState {}

final class TeamsControllerLoading extends TeamsControllerState {}

final class TeamsControllerLoaded extends TeamsControllerState {
  final List<Team> teams;

  const TeamsControllerLoaded({required this.teams});
}

class TeamsControllerFailureState extends TeamsControllerState {
  final TeamFailure teamFailure;

  const TeamsControllerFailureState({required this.teamFailure});
}