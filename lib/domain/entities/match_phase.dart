// ignore_for_file: public_member_api_docs

/// Spielphasen der WM 2026 mit entsprechenden Regeln
enum MatchPhase {
  groupStage('Vorrunde', 1, 3),
  roundOf16('16tel-Finale', 1, 4),
  quarterFinal('Achtel-Finale', 2, 2),
  semiFinal('Viertel-Finale', 3, 1),
  finalStage('Halbfinale & Finale', 3, 2);

  const MatchPhase(this.displayName, this.pointMultiplier, this.maxJokers);

  /// Anzeigename der Phase
  final String displayName;

  /// Multiplikator für Punkte in dieser Phase
  final int pointMultiplier;

  /// Maximale Anzahl an Jokern in dieser Phase
  final int maxJokers;

  /// Bestimmt die Phase basierend auf dem matchDay
  static MatchPhase fromMatchDay(int matchDay) {
    if (matchDay <= 3) {
      return MatchPhase.groupStage;
    }
    switch (matchDay) {
      case 4:
        return MatchPhase.roundOf16;
      case 5:
        return MatchPhase.quarterFinal;
      case 6:
        return MatchPhase.semiFinal;
      case 7:
      case 8:
        return MatchPhase.finalStage;
      default:
        return MatchPhase.groupStage;
    }
  }

  /// Gibt die Anzahl der verfügbaren Joker für diese Phase zurück
  int get availableJokers => maxJokers;

  /// Gibt den Multiplikator für diese Phase zurück
  int get multiplier => pointMultiplier;

  List<int> getMatchDaysForPhase(MatchPhase phase) {
    switch (phase) {
      case MatchPhase.groupStage:
        return [1, 2, 3];
      case MatchPhase.roundOf16:
        return [4];
      case MatchPhase.quarterFinal:
        return [5];
      case MatchPhase.semiFinal:
        return [6];
      case MatchPhase.finalStage:
        return [7, 8]; // ✅ Halbfinale UND Finale teilen sich die Joker!
    }
  }
}
