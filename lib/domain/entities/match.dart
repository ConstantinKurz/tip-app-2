// ignore_for_file: public_member_api_docs, sort_constructors_first

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
      return 'Gruppenphase, Tag ${matchDay + 1}';
    }
    switch (matchDay) {
      case 3:
        return 'Sechszehntelfinale';
      case 4:
        return 'Achtelfinale';
      case 5:
        return 'Viertelfinale';
      case 6:
        return 'Halbfinale';
      case 7:
        return 'Finale';
      default:
        return 'Spieltag $matchDay';
    }
  }   
  
  bool get hasResult {
      return homeScore != null && guestScore != null;
      }
}
