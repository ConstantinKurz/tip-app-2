part of 'tipscontroller_bloc.dart';

@immutable
sealed class TipControllerState {}

final class TipControllerInitial extends TipControllerState {}

final class TipControllerLoading extends TipControllerState {}

class TipControllerFailure extends TipControllerState {
  final TipFailure tipFailure;
  TipControllerFailure({
    required this.tipFailure,
  });
}

final class TipControllerLoaded extends TipControllerState {
  final Map<String, List<Tip>> tips;
  final Map<int, MatchDayStatistics> matchDayStatistics;

  TipControllerLoaded({
    required this.tips,
    this.matchDayStatistics = const {},
  });

  TipControllerLoaded copyWith({
    Map<String, List<Tip>>? tips,
    Map<int, MatchDayStatistics>? matchDayStatistics,
  }) {
    return TipControllerLoaded(
      tips: tips ?? this.tips,
      matchDayStatistics: matchDayStatistics ?? this.matchDayStatistics,
    );
  }
}

