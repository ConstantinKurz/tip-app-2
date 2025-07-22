part of 'ranking_bloc.dart';

@immutable
sealed class RankingEvent {}

class LoadRankingEvent extends RankingEvent {}

class ToggleRankingViewEvent extends RankingEvent {}

class RankingLoadedEvent extends RankingEvent{
  final Either<AuthFailure, List<AppUser>> failureOrUsers;

  RankingLoadedEvent({required this.failureOrUsers});
}
