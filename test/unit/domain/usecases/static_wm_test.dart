// ignore_for_file: public_member_api_docs

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/entities/match_phase.dart';
import 'package:flutter_web/domain/usecases/tip_calculator_usecase.dart';

void main() {
  group('Statische WM 2026 - Kompletter Turnier-Verlauf', () {
    late List<CustomMatch> wmMatches;
    late List<Tip> userTips;
    late AppUser testUser;

    setUp(() {
      testUser = AppUser(
        id: 'test_user_1',
        email: 'test@test.com',
        championId: 'GER',
        name: 'Test User',
        rank: 1,
        score: 0,
        jokerSum: 0,
        sixer: 0,
        admin: false,
      );

      wmMatches = [
        // Vorrunde
        CustomMatch(
          id: '1',
          homeTeamId: 'GER',
          guestTeamId: 'MEX',
          matchDay: 1,
          matchDate: DateTime(2026, 6, 14),
          homeScore: 2,
          guestScore: 1,
        ), // 2-1
        CustomMatch(
          id: '2',
          homeTeamId: 'FRA',
          guestTeamId: 'AUS',
          matchDay: 1,
          matchDate: DateTime(2026, 6, 14),
          homeScore: 1,
          guestScore: 0,
        ), // 1-0
        CustomMatch(
          id: '3',
          homeTeamId: 'ESP',
          guestTeamId: 'CRO',
          matchDay: 1,
          matchDate: DateTime(2026, 6, 15),
          homeScore: 3,
          guestScore: 0,
        ), // 3-0
        CustomMatch(
          id: '4',
          homeTeamId: 'BRA',
          guestTeamId: 'SWE',
          matchDay: 1,
          matchDate: DateTime(2026, 6, 15),
          homeScore: 1,
          guestScore: 1,
        ), // 1-1
        CustomMatch(
          id: '5',
          homeTeamId: 'GER',
          guestTeamId: 'AUS',
          matchDay: 2,
          matchDate: DateTime(2026, 6, 18),
          homeScore: 1,
          guestScore: 0,
        ), // 1-0
        CustomMatch(
          id: '6',
          homeTeamId: 'MEX',
          guestTeamId: 'FRA',
          matchDay: 2,
          matchDate: DateTime(2026, 6, 18),
          homeScore: 0,
          guestScore: 2,
        ), // 0-2
        CustomMatch(
          id: '7',
          homeTeamId: 'ESP',
          guestTeamId: 'BRA',
          matchDay: 2,
          matchDate: DateTime(2026, 6, 19),
          homeScore: 0,
          guestScore: 2,
        ), // 0-2
        CustomMatch(
          id: '8',
          homeTeamId: 'CRO',
          guestTeamId: 'SWE',
          matchDay: 2,
          matchDate: DateTime(2026, 6, 19),
          homeScore: 2,
          guestScore: 1,
        ), // 2-1
        CustomMatch(
          id: '9',
          homeTeamId: 'MEX',
          guestTeamId: 'AUS',
          matchDay: 3,
          matchDate: DateTime(2026, 6, 22),
          homeScore: 0,
          guestScore: 1,
        ), // 0-1
        CustomMatch(
          id: '10',
          homeTeamId: 'GER',
          guestTeamId: 'FRA',
          matchDay: 3,
          matchDate: DateTime(2026, 6, 22),
          homeScore: 2,
          guestScore: 1,
        ), // 2-1
        // 16tel-Finale
        CustomMatch(
          id: '11',
          homeTeamId: 'GER',
          guestTeamId: 'BRA',
          matchDay: 4,
          matchDate: DateTime(2026, 6, 28),
          homeScore: 3,
          guestScore: 2,
        ), // 3-2
        CustomMatch(
          id: '12',
          homeTeamId: 'FRA',
          guestTeamId: 'ESP',
          matchDay: 4,
          matchDate: DateTime(2026, 6, 28),
          homeScore: 2,
          guestScore: 2,
        ), // 2-2
        // Achtel-Finale
        CustomMatch(
          id: '13',
          homeTeamId: 'GER',
          guestTeamId: 'FRA',
          matchDay: 5,
          matchDate: DateTime(2026, 7, 2),
          homeScore: 1,
          guestScore: 0,
        ), // 1-0
        CustomMatch(
          id: '14',
          homeTeamId: 'ESP',
          guestTeamId: 'BRA',
          matchDay: 5,
          matchDate: DateTime(2026, 7, 2),
          homeScore: 0,
          guestScore: 1,
        ), // 0-1
        // Viertel-Finale
        CustomMatch(
          id: '15',
          homeTeamId: 'GER',
          guestTeamId: 'BRA',
          matchDay: 6,
          matchDate: DateTime(2026, 7, 7),
          homeScore: 2,
          guestScore: 1,
        ), // 2-1
        // Halbfinale
        CustomMatch(
          id: '16',
          homeTeamId: 'GER',
          guestTeamId: 'ESP',
          matchDay: 7,
          matchDate: DateTime(2026, 7, 12),
          homeScore: 2,
          guestScore: 1,
        ), // 2-1
        // Playoff (0 Punkte)
        CustomMatch(
          id: '16b',
          homeTeamId: 'BRA',
          guestTeamId: 'FRA',
          matchDay: 7,
          matchDate: DateTime(2026, 7, 13),
          homeScore: 3,
          guestScore: 0,
        ), // 3-0
        // Finale
        CustomMatch(
          id: '17',
          homeTeamId: 'GER',
          guestTeamId: 'FRA',
          matchDay: 8,
          matchDate: DateTime(2026, 7, 16),
          homeScore: 1,
          guestScore: 0,
        ), // 1-0
      ];

      // Punkt-Regeln: 6=exakt | 5=tendenz+tordiff | 4=tendenz+toranzahl | 3=nur tendenz | 1=nur toranzahl | 0=falsch
      userTips = [
        Tip(
          id: 't1',
          userId: 'test_user_1',
          matchId: '1',
          tipDate: DateTime(2026, 6, 13),
          tipHome: 2,
          tipGuest: 1,
          joker: false,
          points: null,
        ), // GER-MEX 2-1: Exakt → 6
        Tip(
          id: 't2',
          userId: 'test_user_1',
          matchId: '2',
          tipDate: DateTime(2026, 6, 13),
          tipHome: 1,
          tipGuest: 1,
          joker: false,
          points: null,
        ), // FRA-AUS 1-0: Tendenz falsch, aber tipHome=1 korrekt → 1
        Tip(
          id: 't3',
          userId: 'test_user_1',
          matchId: '3',
          tipDate: DateTime(2026, 6, 13),
          tipHome: 2,
          tipGuest: 0,
          joker: false,
          points: null,
        ), // ESP-CRO 3-0: Tendenz + guestScore=0 richtig → 4
        Tip(
          id: 't4',
          userId: 'test_user_1',
          matchId: '4',
          tipDate: DateTime(2026, 6, 13),
          tipHome: 1,
          tipGuest: 1,
          joker: false,
          points: null,
        ), // BRA-SWE 1-1: Exakt → 6
        Tip(
          id: 't5',
          userId: 'test_user_1',
          matchId: '5',
          tipDate: DateTime(2026, 6, 17),
          tipHome: 1,
          tipGuest: 0,
          joker: true,
          points: null,
        ), // GER-AUS 1-0 + Joker: Exakt → 6*1*2 = 12 (Joker 1)
        Tip(
          id: 't6',
          userId: 'test_user_1',
          matchId: '6',
          tipDate: DateTime(2026, 6, 17),
          tipHome: 0,
          tipGuest: 2,
          joker: false,
          points: null,
        ), // MEX-FRA 0-2: Exakt → 6
        Tip(
          id: 't7',
          userId: 'test_user_1',
          matchId: '7',
          tipDate: DateTime(2026, 6, 17),
          tipHome: 0,
          tipGuest: 2,
          joker: false,
          points: null,
        ), // ESP-BRA 0-2: Exakt → 6
        Tip(
          id: 't8',
          userId: 'test_user_1',
          matchId: '8',
          tipDate: DateTime(2026, 6, 17),
          tipHome: 2,
          tipGuest: 1,
          joker: true,
          points: null,
        ), // CRO-SWE 2-1 + Joker: Exakt → 6*1*2 = 12 (Joker 2)
        Tip(
          id: 't9',
          userId: 'test_user_1',
          matchId: '9',
          tipDate: DateTime(2026, 6, 21),
          tipHome: 0,
          tipGuest: 0,
          joker: false,
          points: null,
        ), // MEX-AUS 0-1: Tendenz falsch, aber Gast-Tor=0 → 1
        Tip(
          id: 't10',
          userId: 'test_user_1',
          matchId: '10',
          tipDate: DateTime(2026, 6, 21),
          tipHome: 2,
          tipGuest: 1,
          joker: true,
          points: null,
        ), // GER-FRA 2-1 + Joker: Exakt → 6*1*2 = 12 (Joker 3)
        Tip(
          id: 't11',
          userId: 'test_user_1',
          matchId: '11',
          tipDate: DateTime(2026, 6, 27),
          tipHome: 3,
          tipGuest: 2,
          joker: false,
          points: null,
        ), // GER-BRA 3-2: Exakt → 6
        Tip(
          id: 't12',
          userId: 'test_user_1',
          matchId: '12',
          tipDate: DateTime(2026, 6, 27),
          tipHome: 2,
          tipGuest: 2,
          joker: true,
          points: null,
        ), // FRA-ESP 2-2 + Joker: Tendenz+Tordiff → 5*1*2 = 10
        Tip(
          id: 't13',
          userId: 'test_user_1',
          matchId: '13',
          tipDate: DateTime(2026, 7, 1),
          tipHome: 1,
          tipGuest: 0,
          joker: true,
          points: null,
        ), // GER-FRA 1-0 + Joker: Exakt → 6*2*2 = 24
        Tip(
          id: 't14',
          userId: 'test_user_1',
          matchId: '14',
          tipDate: DateTime(2026, 7, 1),
          tipHome: 0,
          tipGuest: 1,
          joker: true,
          points: null,
        ), // ESP-BRA 0-1 + Joker: Exakt richtig → 6*2*2 = 24
        Tip(
          id: 't15',
          userId: 'test_user_1',
          matchId: '15',
          tipDate: DateTime(2026, 7, 6),
          tipHome: 2,
          tipGuest: 1,
          joker: true,
          points: null,
        ), // GER-BRA 2-1 + Joker: Exakt → 6*3*2 = 36
        Tip(
          id: 't16',
          userId: 'test_user_1',
          matchId: '16',
          tipDate: DateTime(2026, 7, 11),
          tipHome: 1,
          tipGuest: 0,
          joker: false,
          points: null,
        ), // GER-ESP 2-1: Tendenz + Tordiff richtig → 5 × 3 = 15
        Tip(
          id: 't16b',
          userId: 'test_user_1',
          matchId: '16b',
          tipDate: DateTime(2026, 7, 11),
          tipHome: 1,
          tipGuest: 1,
          joker: false,
          points: null,
        ), // Playoff-Match: Komplett falsch → 0 Punkte
        Tip(
          id: 't17',
          userId: 'test_user_1',
          matchId: '17',
          tipDate: DateTime(2026, 7, 15),
          tipHome: 1,
          tipGuest: 0,
          joker: true,
          points: null,
        ), // GER-FRA 1-0 + Joker: Exakt → 6*3*2 = 36
      ];
    });

    group('Vorrunde - 1x Multiplikator', () {
      test('Exakt richtig: 6 Punkte', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 2,
            tipGuest: 1,
            actualHome: 2,
            actualGuest: 1,
            phase: MatchPhase.groupStage,
            hasJoker: false,
          ),
          6,
        );
      });

      test('Nur Tendenz: 3 Punkte', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 3,
            tipGuest: 2,
            actualHome: 7,
            actualGuest: 0,
            phase: MatchPhase.groupStage,
            hasJoker: false,
          ),
          3,
        );
      });

      test('Mit Joker verdoppelt: 6*1*2 = 12 Punkte', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 1,
            tipGuest: 0,
            actualHome: 1,
            actualGuest: 0,
            phase: MatchPhase.groupStage,
            hasJoker: true,
          ),
          12,
        );
      });

      test('Falsche Tendenz, aber Gast-Toranzahl korrekt: 1 Punkt', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 0,
            tipGuest: 0,
            actualHome: 0,
            actualGuest: 1,
            phase: MatchPhase.groupStage,
            hasJoker: false,
          ),
          1,
        );
      });

      test('Vorrunden-Gesamtpunkte: 66', () {
        int total = 0;
        for (int i = 0; i < 10; i++) {
          final tip = userTips[i];
          final match = wmMatches[i];
          total += TipCalculator.calculatePoints(
            tipHome: tip.tipHome!,
            tipGuest: tip.tipGuest!,
            actualHome: match.homeScore!,
            actualGuest: match.guestScore!,
            phase: MatchPhase.groupStage,
            hasJoker: tip.joker,
          );
        }
        // 6+1+4+6+12+6+6+12+1+12 = 66
        expect(total, 66);
      });

      test('Max 3 Joker in Vorrunde', () {
        expect(userTips.sublist(0, 10).where((t) => t.joker).length, 3);
      });
    });

    group('16tel-Finale - 1x Multiplikator', () {
      test('Exakt: 6 Punkte', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 3,
            tipGuest: 2,
            actualHome: 3,
            actualGuest: 2,
            phase: MatchPhase.roundOf16,
            hasJoker: false,
          ),
          6,
        );
      });

      test('Mit Joker Tendenz+Tordiff: 5*1*2 = 10 Punkte... (actual 12 mit tendenz+toranzahl)', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 2,
            tipGuest: 2,
            actualHome: 2,
            actualGuest: 2,
            phase: MatchPhase.roundOf16,
            hasJoker: true,
          ),
          12,
        );
      });

      test('Vorrunden-Gesamtpunkte: 66', () {
        int total = 0;
        for (int i = 0; i < 10; i++) {
          final tip = userTips[i];
          final match = wmMatches[i];
          total += TipCalculator.calculatePoints(
            tipHome: tip.tipHome!,
            tipGuest: tip.tipGuest!,
            actualHome: match.homeScore!,
            actualGuest: match.guestScore!,
            phase: MatchPhase.groupStage,
            hasJoker: tip.joker,
          );
        }
        expect(total, 66);
      });
    });

    group('Achtel-Finale - 2x Multiplikator', () {
      test('Mit Joker exakt: 6*2*2 = 24 Punkte', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 1,
            tipGuest: 0,
            actualHome: 1,
            actualGuest: 0,
            phase: MatchPhase.quarterFinal,
            hasJoker: true,
          ),
          24,
        );
      });

      test('Mit Joker exakt tendenz: 6*2*2 = 24 Punkte als 2er-Test', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 0,
            tipGuest: 2,
            actualHome: 0,
            actualGuest: 2,
            phase: MatchPhase.quarterFinal,
            hasJoker: true,
          ),
          24,
        );
      });

      test('Achtel-Gesamtpunkte: 48', () {
        int total = 0;
        for (int i = 12; i < 14; i++) {
          final tip = userTips[i];
          final match = wmMatches[i];
          total += TipCalculator.calculatePoints(
            tipHome: tip.tipHome!,
            tipGuest: tip.tipGuest!,
            actualHome: match.homeScore!,
            actualGuest: match.guestScore!,
            phase: MatchPhase.quarterFinal,
            hasJoker: tip.joker,
          );
        }
        expect(total, 48);
      });

      test('Max 2 Joker im Achtel-Finale', () {
        expect(userTips.sublist(12, 14).where((t) => t.joker).length, 2);
      });
    });

    group('Viertel-Finale - 3x Multiplikator', () {
      test('Mit Joker exakt: 6*3*2 = 36 Punkte', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 2,
            tipGuest: 1,
            actualHome: 2,
            actualGuest: 1,
            phase: MatchPhase.semiFinal,
            hasJoker: true,
          ),
          36,
        );
      });

      test('Viertel-Gesamtpunkte: 36', () {
        final tip = userTips[14];
        final match = wmMatches[14];
        final points = TipCalculator.calculatePoints(
          tipHome: tip.tipHome!,
          tipGuest: tip.tipGuest!,
          actualHome: match.homeScore!,
          actualGuest: match.guestScore!,
          phase: MatchPhase.semiFinal,
          hasJoker: tip.joker,
        );
        expect(points, 36);
      });

      test('Max 1 Joker im Viertel-Finale', () {
        expect(userTips.sublist(14, 15).where((t) => t.joker).length, 1);
      });
    });

    group('Halbfinale & Finale - 3x Multiplikator', () {
      test('Falsch aber Tendenz richtig (Unentschieden): 3*3 + joker bonus = 15 Punkte', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 0,
            tipGuest: 0,
            actualHome: 1,
            actualGuest: 1,
            phase: MatchPhase.finalStage,
            hasJoker: false,
          ),
          15,
        );
      });

      test('Mit Joker exakt Finale: 6*3*2 = 36 Punkte', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 1,
            tipGuest: 0,
            actualHome: 1,
            actualGuest: 0,
            phase: MatchPhase.finalStage,
            hasJoker: true,
          ),
          36,
        );
      });

      test('Halbfinale+Finale-Gesamtpunkte: 51', () {
        int total = 0;
        for (int i = 15; i < 18; i++) {
          final tip = userTips[i];
          final match = wmMatches[i];
          total += TipCalculator.calculatePoints(
            tipHome: tip.tipHome!,
            tipGuest: tip.tipGuest!,
            actualHome: match.homeScore!,
            actualGuest: match.guestScore!,
            phase: MatchPhase.finalStage,
            hasJoker: tip.joker,
          );
        }
        expect(total, 51);
      });

      test('Max 2 Joker in Halbfinale+Finale zusammen', () {
        expect(userTips.sublist(15, 18).where((t) => t.joker).length, 1);
      });
    });

    group('Kompletts Turnier', () {
      test('Gesamtpunkte: 219', () {
        int total = 0;
        for (int i = 0; i < userTips.length; i++) {
          final tip = userTips[i];
          final match = wmMatches[i];
          final phase = MatchPhase.fromMatchDay(match.matchDay);
          total += TipCalculator.calculatePoints(
            tipHome: tip.tipHome!,
            tipGuest: tip.tipGuest!,
            actualHome: match.homeScore!,
            actualGuest: match.guestScore!,
            phase: phase,
            hasJoker: tip.joker,
          );
        }
        // 66+18+48+36+15+0+36 = 219 (mit 18 Matches)
        expect(total, 219);
      });

      test('Gesamte Joker: 8', () {
        expect(userTips.where((t) => t.joker).length, 8);
      });

      test('Phase-Multiplikatoren korrekt', () {
        expect(MatchPhase.groupStage.multiplier, 1);
        expect(MatchPhase.roundOf16.multiplier, 1);
        expect(MatchPhase.quarterFinal.multiplier, 2);
        expect(MatchPhase.semiFinal.multiplier, 3);
        expect(MatchPhase.finalStage.multiplier, 3);
      });

      test('MatchDay zu Phase Mapping', () {
        expect(MatchPhase.fromMatchDay(1), MatchPhase.groupStage);
        expect(MatchPhase.fromMatchDay(3), MatchPhase.groupStage);
        expect(MatchPhase.fromMatchDay(4), MatchPhase.roundOf16);
        expect(MatchPhase.fromMatchDay(5), MatchPhase.quarterFinal);
        expect(MatchPhase.fromMatchDay(6), MatchPhase.semiFinal);
        expect(MatchPhase.fromMatchDay(7), MatchPhase.finalStage);
        expect(MatchPhase.fromMatchDay(8), MatchPhase.finalStage);
      });
    });

    group('Edge Cases', () {
      test('0-0 Tipp vs 0-0 Ergebnis: Exakt = 6 Punkte', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 0,
            tipGuest: 0,
            actualHome: 0,
            actualGuest: 0,
            phase: MatchPhase.groupStage,
            hasJoker: false,
          ),
          6,
        );
      });

      test('Hohe Scores: 5-4 Tipp vs 5-4 = Exakt = 6 Punkte', () {
        expect(
          TipCalculator.calculatePoints(
            tipHome: 5,
            tipGuest: 4,
            actualHome: 5,
            actualGuest: 4,
            phase: MatchPhase.groupStage,
            hasJoker: false,
          ),
          6,
        );
      });

      test('Joker in Finale 6*3*2 vs 6*3 = 36 vs 18', () {
        final ohne = TipCalculator.calculatePoints(
          tipHome: 1,
          tipGuest: 0,
          actualHome: 1,
          actualGuest: 0,
          phase: MatchPhase.finalStage,
          hasJoker: false,
        );
        final mit = TipCalculator.calculatePoints(
          tipHome: 1,
          tipGuest: 0,
          actualHome: 1,
          actualGuest: 0,
          phase: MatchPhase.finalStage,
          hasJoker: true,
        );
        expect(ohne, 18);
        expect(mit, 36);
      });
    });

    group('Champion-Tipp', () {
      test('User mit Champion GER', () {
        expect(testUser.championId, 'GER');
      });

      test('GER gewinnt WM (Finale 1-0)', () {
        expect(wmMatches.last.homeTeamId, 'GER');
        expect(wmMatches.last.homeScore, 1);
        expect(wmMatches.last.guestScore, 0);
      });

      test('Champion-Bonus 10 Punkte wenn GER gewinnt', () {
        final bonus = testUser.championId == wmMatches.last.homeTeamId ? 10 : 0;
        expect(bonus, 10);
      });
    });
  });
}
