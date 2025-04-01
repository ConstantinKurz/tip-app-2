part of 'matchescontroller_bloc.dart';

@immutable
sealed class MatchesControllerState {}

final class MatchesControllerInitial extends MatchesControllerState {}

class MatchesControllerLoading extends MatchesControllerState {}

class MatchesControllerLoaded extends MatchesControllerState {
  final List<CustomMatch> matches;

  MatchesControllerLoaded({required this.matches});
}

class MatchesControllerFailure extends MatchesControllerState {
  final MatchFailure matchFailure;
  MatchesControllerFailure({required this.matchFailure});
}


