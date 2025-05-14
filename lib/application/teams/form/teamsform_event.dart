part of 'teamsform_bloc.dart';

@immutable
sealed class TeamsformEvent {}

class TeamFormCreateEvent extends TeamsformEvent {
  final Team? team;

  TeamFormCreateEvent({required this.team});
}

class TeamFormUpdateEvent extends TeamsformEvent {
  final Team? team;

  TeamFormUpdateEvent({required this.team});
}

class TeamFormFieldUpdatedEvent extends TeamsformEvent {
  final String? id;
  final String? name;
  final String? flagCode;
  final int? winPoints;
  final bool? champion;

  TeamFormFieldUpdatedEvent({
      this.id, this.name, this.flagCode, this.winPoints, this.champion});
}

class TeamFormDeleteEvent extends TeamsformEvent {
  final String id;

  TeamFormDeleteEvent({required this.id});
}
