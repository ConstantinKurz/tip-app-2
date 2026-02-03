class MatchDayStatistics {
  final int jokersUsed;
  final int jokersAvailable;
  final int tippedGames;
  final int totalGames;
  final int matchDay;

  MatchDayStatistics({
    required this.jokersUsed,
    required this.jokersAvailable,
    required this.tippedGames,
    required this.totalGames,
    required this.matchDay,
  });

  bool get isJokerAvailable => jokersUsed < jokersAvailable;

  MatchDayStatistics copyWith({
    int? jokersUsed,
    int? jokersAvailable,
    int? tippedGames,
    int? totalGames,
    int? matchDay,
  }) {
    return MatchDayStatistics(
      jokersUsed: jokersUsed ?? this.jokersUsed,
      jokersAvailable: jokersAvailable ?? this.jokersAvailable,
      tippedGames: tippedGames ?? this.tippedGames,
      totalGames: totalGames ?? this.totalGames,
      matchDay: matchDay ?? this.matchDay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchDayStatistics &&
          runtimeType == other.runtimeType &&
          jokersUsed == other.jokersUsed &&
          jokersAvailable == other.jokersAvailable &&
          tippedGames == other.tippedGames &&
          totalGames == other.totalGames &&
          matchDay == other.matchDay;

  @override
  int get hashCode =>
      jokersUsed.hashCode ^
      jokersAvailable.hashCode ^
      tippedGames.hashCode ^
      totalGames.hashCode ^
      matchDay.hashCode;
}
