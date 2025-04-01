// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'matchesform_bloc.dart';

@immutable
sealed class MatchesformEvent {}

class CreateMatchEvent extends MatchesformEvent {
  final UniqueID? homeTeamId;
  final UniqueID? guestTeamId;
  final DateTime? matchDate;
  final int? matchDay;

  CreateMatchEvent(
      {required this.homeTeamId,
      required this.guestTeamId,
      required this.matchDate,
      required this.matchDay});
}

class UpdateMatchEvent extends MatchesformEvent {
  final UniqueID id;
  final UniqueID? homeTeamId;
  final UniqueID? guestTeamId;
  final DateTime? matchDate;
  final int? matchDay;
  UpdateMatchEvent({
    required this.id,
    this.homeTeamId,
    this.guestTeamId,
    this.matchDate,
    this.matchDay,
  });
}
