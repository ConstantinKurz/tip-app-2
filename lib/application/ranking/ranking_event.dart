part of 'ranking_bloc.dart';

@immutable
sealed class RankingEvent {}

class LoadRankingEvent extends RankingEvent {}

class ToggleExpandedEvent extends RankingEvent {}