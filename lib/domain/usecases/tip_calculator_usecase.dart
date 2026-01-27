// ignore_for_file: public_member_api_docs

import '../entities/match_phase.dart';

/// Berechnet Punkte für Tipps nach WM 2026 Variante 3+ Regeln
class TipCalculator {
  /// Berechnet die Punkte für einen Tipp
  /// 
  /// [tipHome] - Getippte Heimtore
  /// [tipGuest] - Getippte Auswärtstore
  /// [actualHome] - Tatsächliche Heimtore
  /// [actualGuest] - Tatsächliche Auswärtstore
  /// [phase] - Spielphase für Multiplikator
  /// [hasJoker] - Ob Joker gesetzt wurde
  /// 
  /// Rückgabe: Berechnete Punkte
  static int calculatePoints({
    required int tipHome,
    required int tipGuest,
    required int actualHome,
    required int actualGuest,
    required MatchPhase phase,
    required bool hasJoker,
  }) {
    // Basis-Punkte berechnen
    final basePoints = _calculateBasePoints(
      tipHome: tipHome,
      tipGuest: tipGuest,
      actualHome: actualHome,
      actualGuest: actualGuest,
    );

    // Multiplikator der Phase anwenden
    final multipliedPoints = basePoints * phase.multiplier;

    // Joker verdoppelt die Punkte
    final finalPoints = hasJoker ? multipliedPoints * 2 : multipliedPoints;

    return finalPoints;
  }

  /// Berechnet die Basis-Punkte nach den Regeln
  static int _calculateBasePoints({
    required int tipHome,
    required int tipGuest,
    required int actualHome,
    required int actualGuest,
  }) {
    // 1. Komplett richtig: 6 Punkte
    if (tipHome == actualHome && tipGuest == actualGuest) {
      return 6;
    }

    final tipDiff = tipHome - tipGuest;
    final actualDiff = actualHome - actualGuest;
    final tipTendency = tipDiff > 0 ? 1 : (tipDiff < 0 ? -1 : 0);
    final actualTendency = actualDiff > 0 ? 1 : (actualDiff < 0 ? -1 : 0);

    // Tendenz falsch oder beide Unentschieden aber unterschiedlich
    if (tipTendency != actualTendency) {
      // 5. Nur Toranzahl eines Teams: 1 Punkt
      if (tipHome == actualHome || tipGuest == actualGuest) {
        return 1;
      }
      return 0;
    }

    // Ab hier ist die Tendenz richtig
    // 3. Richtige Tendenz + Toranzahl eines Teams: 4 Punkte
    if (tipHome == actualHome || tipGuest == actualGuest) {
      return 4;
    }

    // 2. Richtige Tendenz + Tordifferenz: 5 Punkte
    if ( tipDiff == actualDiff) {
      return 5;
    }

    // 4. Nur richtige Tendenz: 3 Punkte
    return 3;
  }

  /// Hilfsmethode: Gibt eine Beschreibung der Punktevergabe zurück
  static String getPointsDescription({
    required int tipHome,
    required int tipGuest,
    required int actualHome,
    required int actualGuest,
  }) {
    final points = _calculateBasePoints(
      tipHome: tipHome,
      tipGuest: tipGuest,
      actualHome: actualHome,
      actualGuest: actualGuest,
    );

    switch (points) {
      case 6:
        return 'Exakt richtig!';
      case 5:
        return 'Richtige Tendenz + Tordifferenz';
      case 4:
        return 'Richtige Tendenz + Toranzahl eines Teams';
      case 3:
        return 'Richtige Tendenz';
      case 1:
        return 'Toranzahl eines Teams';
      default:
        return 'Leider falsch';
    }
  }
}
