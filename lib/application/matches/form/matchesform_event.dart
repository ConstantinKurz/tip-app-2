// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'matchesform_bloc.dart';

@immutable
sealed class MatchesformEvent {}

class CreateMatchEvent extends MatchesformEvent {
  final String? id;
  final String? homeTeamId;
  final String? guestTeamId;
  final DateTime? matchDate;
  final int? matchDay;

  CreateMatchEvent(
      {required this.id,
      required this.homeTeamId,
      required this.guestTeamId,
      required this.matchDate,
      required this.matchDay});
}

class MatchFormFieldUpdatedEvent extends MatchesformEvent {
  final String? homeTeamId;
  final String? guestTeamId;
  final DateTime? matchDate;
  final TimeOfDay? matchTime;
  final int? matchDay;

  MatchFormFieldUpdatedEvent(
      {this.homeTeamId,
      this.guestTeamId,
      this.matchDate,
      this.matchTime,
      this.matchDay});
}

class MatchFormUpdateEvent extends MatchesformEvent {
  final CustomMatch? match;
  MatchFormUpdateEvent({required this.match});
}

class MatchFormUpdatedEvent extends MatchesformEvent {
  final Either<MatchFailure, Unit> failureOrSuccess;

  MatchFormUpdatedEvent({required this.failureOrSuccess});
}

class MatchFormDeleteEvent extends MatchesformEvent {
  final String id;
  MatchFormDeleteEvent({
    required this.id,
  });
}
