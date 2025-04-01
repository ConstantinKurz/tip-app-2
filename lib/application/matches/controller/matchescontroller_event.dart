// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'matchescontroller_bloc.dart';

abstract class MatchesControllerEvent {}

class MatchesAllEvent extends MatchesControllerEvent {}

class MatchUpdatedEvent extends MatchesControllerEvent {
  final Either<MatchFailure, List<CustomMatch>> failureOrMatches;
  MatchUpdatedEvent({
    required this.failureOrMatches,
  });
}

class DeleteMatchEvent extends MatchesControllerEvent {
  final Match match;
  DeleteMatchEvent(this.match);
}