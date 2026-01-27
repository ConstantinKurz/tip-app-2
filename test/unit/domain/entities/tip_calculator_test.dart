import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/domain/usecases/tip_calculator_usecase.dart';
import 'package:flutter_web/domain/entities/match_phase.dart';

void main() {
  group('TipCalculator', () {
    group('Basis-Punkte Berechnung', () {
      test('Komplett richtig gibt 6 Punkte', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 3,
          tipGuest: 2,
          actualHome: 3,
          actualGuest: 2,
          phase: MatchPhase.groupStage,
          hasJoker: false,
        );
        expect(points, 6);
      });

      test('Richtige Tendenz + Tordifferenz gibt 5 Punkte', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 3,
          tipGuest: 2,
          actualHome: 1,
          actualGuest: 0,
          phase: MatchPhase.groupStage,
          hasJoker: false,
        );
        expect(points, 5);
      });

      test('Richtige Tendenz + Toranzahl eines Teams gibt 4 Punkte', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 3,
          tipGuest: 2,
          actualHome: 3,
          actualGuest: 0,
          phase: MatchPhase.groupStage,
          hasJoker: false,
        );
        expect(points, 4);
      });

      test('Nur richtige Tendenz gibt 3 Punkte', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 3,
          tipGuest: 2,
          actualHome: 7,
          actualGuest: 0,
          phase: MatchPhase.groupStage,
          hasJoker: false,
        );
        expect(points, 3);
      });

      test('Nur Toranzahl eines Teams gibt 1 Punkt', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 3,
          tipGuest: 2,
          actualHome: 0,
          actualGuest: 2,
          phase: MatchPhase.groupStage,
          hasJoker: false,
        );
        expect(points, 1);
      });

      test('Komplett falsch gibt 0 Punkte', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 3,
          tipGuest: 2,
          actualHome: 0,
          actualGuest: 5,
          phase: MatchPhase.groupStage,
          hasJoker: false,
        );
        expect(points, 0);
      });
    });

    group('Multiplikator pro Phase', () {
      test('Vorrunde: einfache Wertung (1x)', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 2,
          tipGuest: 1,
          actualHome: 2,
          actualGuest: 1,
          phase: MatchPhase.groupStage,
          hasJoker: false,
        );
        expect(points, 6); // 6 * 1 = 6
      });

      test('16tel-Finale: einfache Wertung (1x)', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 2,
          tipGuest: 1,
          actualHome: 2,
          actualGuest: 1,
          phase: MatchPhase.roundOf16,
          hasJoker: false,
        );
        expect(points, 6); // 6 * 1 = 6
      });

      test('Achtelfinale: doppelte Wertung (2x)', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 2,
          tipGuest: 1,
          actualHome: 2,
          actualGuest: 1,
          phase: MatchPhase.quarterFinal,
          hasJoker: false,
        );
        expect(points, 12); // 6 * 2 = 12
      });

      test('Viertelfinale: dreifache Wertung (3x)', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 2,
          tipGuest: 1,
          actualHome: 2,
          actualGuest: 1,
          phase: MatchPhase.semiFinal,
          hasJoker: false,
        );
        expect(points, 18); // 6 * 3 = 18
      });

      test('Halbfinale/Finale: dreifache Wertung (3x)', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 2,
          tipGuest: 1,
          actualHome: 2,
          actualGuest: 1,
          phase: MatchPhase.finalStage,
          hasJoker: false,
        );
        expect(points, 18); // 6 * 3 = 18
      });
    });

    group('Joker verdoppelt Punkte', () {
      test('Vorrunde mit Joker: 6 * 1 * 2 = 12 Punkte', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 2,
          tipGuest: 1,
          actualHome: 2,
          actualGuest: 1,
          phase: MatchPhase.groupStage,
          hasJoker: true,
        );
        expect(points, 12); // 6 * 1 * 2 = 12
      });

      test('Achtelfinale mit Joker: 6 * 2 * 2 = 24 Punkte', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 2,
          tipGuest: 1,
          actualHome: 2,
          actualGuest: 1,
          phase: MatchPhase.quarterFinal,
          hasJoker: true,
        );
        expect(points, 24); // 6 * 2 * 2 = 24
      });

      test('Halbfinale mit Joker: 6 * 3 * 2 = 36 Punkte', () {
        final points = TipCalculator.calculatePoints(
          tipHome: 2,
          tipGuest: 1,
          actualHome: 2,
          actualGuest: 1,
          phase: MatchPhase.finalStage,
          hasJoker: true,
        );
        expect(points, 36); // 6 * 3 * 2 = 36
      });
    });

    group('MatchPhase Eigenschaften', () {
      test('Vorrunde hat 3 Joker und Multiplikator 1', () {
        expect(MatchPhase.groupStage.maxJokers, 3);
        expect(MatchPhase.groupStage.pointMultiplier, 1);
      });

      test('16tel hat 4 Joker und Multiplikator 1', () {
        expect(MatchPhase.roundOf16.maxJokers, 4);
        expect(MatchPhase.roundOf16.pointMultiplier, 1);
      });

      test('Achtelfinale hat 2 Joker und Multiplikator 2', () {
        expect(MatchPhase.quarterFinal.maxJokers, 2);
        expect(MatchPhase.quarterFinal.pointMultiplier, 2);
      });

      test('Viertelfinale hat 1 Joker und Multiplikator 3', () {
        expect(MatchPhase.semiFinal.maxJokers, 1);
        expect(MatchPhase.semiFinal.pointMultiplier, 3);
      });

      test('Finale hat 2 Joker und Multiplikator 3', () {
        expect(MatchPhase.finalStage.maxJokers, 2);
        expect(MatchPhase.finalStage.pointMultiplier, 3);
      });
    });

    group('Punkte-Beschreibungen', () {
      test('Gibt korrekte Beschreibung für 6 Punkte', () {
        final description = TipCalculator.getPointsDescription(
          tipHome: 2,
          tipGuest: 1,
          actualHome: 2,
          actualGuest: 1,
        );
        expect(description, 'Exakt richtig!');
      });

      test('Gibt korrekte Beschreibung für 5 Punkte', () {
        final description = TipCalculator.getPointsDescription(
          tipHome: 3,
          tipGuest: 2,
          actualHome: 1,
          actualGuest: 0,
        );
        expect(description, 'Richtige Tendenz + Tordifferenz');
      });
    });
  });
}
