part of 'teams_bloc.dart';

@immutable
sealed class TeamsState {
  const TeamsState();
}

final class TeamInitial extends TeamsState {}

final class TeamsLoading extends TeamsState {}

final class TeamsLoaded extends TeamsState {
  final List<Team> teams;

  const TeamsLoaded({required this.teams});
}

class TeamFailureState extends TeamsState {
  final TeamFailure teamFailure;

  const TeamFailureState({required this.teamFailure});
}