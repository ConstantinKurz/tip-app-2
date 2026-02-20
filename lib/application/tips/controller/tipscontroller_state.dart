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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TipControllerLoaded) return false;
    
    // Vergleiche Tips-Map
    if (tips.length != other.tips.length) return false;
    for (final key in tips.keys) {
      if (!other.tips.containsKey(key)) return false;
      final thisList = tips[key]!;
      final otherList = other.tips[key]!;
      if (thisList.length != otherList.length) return false;
      for (int i = 0; i < thisList.length; i++) {
        if (thisList[i] != otherList[i]) return false;
      }
    }
    
    // Vergleiche Stats-Map
    if (matchDayStatistics.length != other.matchDayStatistics.length) return false;
    for (final key in matchDayStatistics.keys) {
      if (!other.matchDayStatistics.containsKey(key)) return false;
      if (matchDayStatistics[key] != other.matchDayStatistics[key]) return false;
    }
    
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(tips.entries.map((e) => Object.hash(e.key, Object.hashAll(e.value)))),
    Object.hashAll(matchDayStatistics.entries.map((e) => Object.hash(e.key, e.value))),
  );
}

