// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'match_phase.dart';

class CustomMatch {
  final String id;
  final String homeTeamId;
  final String guestTeamId;
  final DateTime matchDate;
  final int matchDay;
  final int? homeScore;
  final int? guestScore;

  CustomMatch({
    required this.id,
    required this.homeTeamId,
    required this.guestTeamId,
    required this.matchDate,
    required this.matchDay,
    required this.homeScore,
    required this.guestScore,
  });

  CustomMatch copyWith({
    String? id,
    String? homeTeamId,
    String? guestTeamId,
    DateTime? matchDate,
    int? matchDay,
    int? homeScore,
    int? guestScore,
  }) {
    return CustomMatch(
      id: id ?? this.id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      guestTeamId: guestTeamId ?? this.guestTeamId,
      matchDate: matchDate ?? this.matchDate,
      matchDay: matchDay ?? this.matchDay,
      homeScore: homeScore ?? this.homeScore,
      guestScore: guestScore ?? this.guestScore,
    );
  }

  factory CustomMatch.empty({
    String? id,
    String? homeTeamId,
    String? guestTeamId,
    DateTime? matchDate,
    int? matchDay,
    int? homeScore,
    int? guestScore,
  }) {
    return CustomMatch(
      id: id ?? "",
      homeTeamId: homeTeamId ?? "TBD",
      guestTeamId: guestTeamId ?? "TBD",
      matchDate: matchDate ?? DateTime.now(),
      matchDay: matchDay ?? 0,
      homeScore: homeScore,
      guestScore: guestScore,
    );
  }

  String get getStageName {
    if (matchDay <= 3) {
      return 'Gruppenphase';
    }
    switch (matchDay) {
      case 4:
        return 'Sechszehntelfinale';
      case 5:
        return 'Achtelfinale';
      case 6:
        return 'Viertelfinale';
      case 7:
        return 'Halbfinale';
      case 8:
        return 'Finale';
      default:
        return 'Spieltag $matchDay';
    }
  }

  /// Gibt den Stage-Namen zurück, mit Unterscheidung zwischen Finale und Spiel um Platz 3.
  /// 
  /// Bei matchDay 8: Das zeitlich spätere Spiel = Finale, das frühere = Spiel um Platz 3
  /// [allMatches] sollte alle Matches enthalten, um den Vergleich zu ermöglichen.
  String getStageNameInContext(List<CustomMatch> allMatches) {
    if (matchDay != 8) {
      return getStageName;
    }
    
    // Finde alle matchDay-8-Spiele
    final matchDay8Matches = allMatches.where((m) => m.matchDay == 8).toList();
    
    // Wenn nur ein Spiel → normal "Finale" zurückgeben
    if (matchDay8Matches.length <= 1) {
      return 'Finale';
    }
    
    // Sortiere nach Zeit (spätestes zuerst)
    matchDay8Matches.sort((a, b) => b.matchDate.compareTo(a.matchDate));
    
    // Das zeitlich letzte Spiel ist das echte Finale
    final finalMatch = matchDay8Matches.first;
    
    if (id == finalMatch.id) {
      return 'Finale';
    } else {
      return 'Spiel um Platz 3';
    }
  }

  /// Gibt die MatchPhase für dieses Spiel zurück
  MatchPhase get phase => MatchPhase.fromMatchDay(matchDay);
  
  bool get hasResult {
    return homeScore != null && guestScore != null;
  }
}
