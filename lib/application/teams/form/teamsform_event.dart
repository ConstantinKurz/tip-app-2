part of 'teamsform_bloc.dart';

@immutable
sealed class TeamsformEvent {}

class TeamFormCreateTeamEvent extends TeamsformEvent {
  final Team? team;

  TeamFormCreateTeamEvent({required this.team});
}

class TeamFormUpdateTeamEvent extends TeamsformEvent {
  final Team team;

  TeamFormUpdateTeamEvent({required this.team});
}

class TeamFormFieldUpdatedEvent extends TeamsformEvent{
  final String? id;
  final String? name;
  final String? flagCode;
  final int? winPoints;
  final bool? champion;

  TeamFormFieldUpdatedEvent(this.id, this.name, this.flagCode, this.winPoints, this.champion);
}

class TeamFormDeleteTeamEvent extends TeamsformEvent {
  final String id;

  TeamFormDeleteTeamEvent({required this.id});
}