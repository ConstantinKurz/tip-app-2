// ignore_for_file: public_member_api_docs

/// Spielphasen der WM 2026 mit entsprechenden Regeln
enum MatchPhase {
  groupStage('Vorrunde', 1, 5, 36),
  roundOf16('16tel-Finale', 1, 4, null),
  roundOf8('8tel-Finale', 2, 2, null),
  quarterFinal('Viertel-Finale', 3, 1, null),
  semiFinal('Halbfinale', 3, 2, null),
  finalStage('Finale', 3, 2, null);

  const MatchPhase(this.displayName, this.pointMultiplier, this.maxJokers, this.maxTips);

  /// Anzeigename der Phase
  final String displayName;

  /// Multiplikator für Punkte in dieser Phase
  final int pointMultiplier;

  /// Maximale Anzahl an Jokern in dieser Phase
  final int maxJokers;

  /// Maximale Anzahl an Tipps in dieser Phase (null = unbegrenzt)
  /// Vorrunde: 36 Tipps erlaubt (8 Gruppen à 6 Spiele = 48 Spiele, aber max 36 Tips)
  final int? maxTips;

  /// Prüft ob ein Tipp-Limit für diese Phase existiert
  bool get hasTipLimit => maxTips != null;

  /// Bestimmt die Phase basierend auf dem matchDay
  static MatchPhase fromMatchDay(int matchDay) {
    if (matchDay <= 3) {
      return MatchPhase.groupStage;
    }
    switch (matchDay) {
      case 4:
        return MatchPhase.roundOf16;
      case 5:
        return MatchPhase.roundOf8;
      case 6:
        return MatchPhase.quarterFinal;
      case 7:
        return MatchPhase.semiFinal; // Halbfinale
      case 8:
        return MatchPhase.finalStage; // Finale
      default:
        return MatchPhase.groupStage;
    }
  }

  /// Gibt die Anzahl der verfügbaren Joker für diese Phase zurück
  int get availableJokers => maxJokers;

  /// Gibt den Multiplikator für diese Phase zurück
  int get multiplier => pointMultiplier;

  /// Für JOKER-Zählung: Halbfinale + Finale teilen sich Joker
  List<int> getMatchDaysForJokerPhase() {
    switch (this) {
      case MatchPhase.groupStage:
        return [1, 2, 3];
      case MatchPhase.roundOf16:
        return [4];
      case MatchPhase.roundOf8:
        return [5];
      case MatchPhase.quarterFinal:
        return [6];
      case MatchPhase.semiFinal:
        return [7, 8]; // ✅ Halbfinale UND Finale teilen sich die Joker!
      case MatchPhase.finalStage:
        return [7, 8]; // ✅ Halbfinale UND Finale teilen sich die Joker!
    }
  }

  /// Für TIPP-Statistik: Nur der aktuelle matchDay
  List<int> getMatchDaysForTippedGamesPhase(int matchDay) {
    return [matchDay]; // ✅ Immer nur der einzelne matchDay
  }

  /// Legacy-Methode für Abwärtskompatibilität
  List<int> getMatchDaysForPhase() {
    return getMatchDaysForJokerPhase();
  }
}
