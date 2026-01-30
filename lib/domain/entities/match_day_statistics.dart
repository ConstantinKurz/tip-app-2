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
}
