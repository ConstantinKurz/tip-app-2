// ignore_for_file: public_member_api_docs, sort_constructors_first

class Tip {
  final String id;
  final String userId;
  final String? matchId;
  final DateTime tipDate;
  final int? tipHome;
  final int? tipGuest;
  final bool joker;
  final int? points;
  Tip(
      {required this.id,
      required this.userId,
      required this.matchId,
      required this.tipDate,
      required this.tipHome,
      required this.tipGuest,
      required this.joker,
      required this.points});

  factory Tip.empty(String userId) {
    return Tip(
      id: "",
      userId: userId,
      matchId: "",
      tipDate: DateTime.now(),
      tipHome: null,
      tipGuest: null,
      joker: false,
      points: null
    );
  }

  Tip copyWith({
    String? id,
    String? userId,
    String? matchId,
    DateTime? tipDate,
    int? tipHome,
    int? tipGuest,
    bool? joker,
    int? points,
  }) {
    return Tip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      matchId: matchId ?? this.matchId,
      tipDate: tipDate ?? this.tipDate,
      tipHome: tipHome ?? this.tipHome,
      tipGuest: tipGuest ?? this.tipGuest,
      joker: joker ?? this.joker,
      points: points ?? this.points
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Tip) return false;
    return id == other.id &&
        userId == other.userId &&
        matchId == other.matchId &&
        tipHome == other.tipHome &&
        tipGuest == other.tipGuest &&
        joker == other.joker &&
        points == other.points;
  }

  @override
  int get hashCode => Object.hash(
    id, userId, matchId, tipHome, tipGuest, joker, points,
  );
}
