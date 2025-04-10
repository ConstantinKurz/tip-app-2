// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_web/domain/entities/id.dart';

class Tip {
  final UniqueID id;
  final UniqueID userId;
  final String? matchId;
  final DateTime tipDate;
  final int? tipHome;
  final int? tipGuest;
  final bool joker;
  Tip(
      {required this.id,
      required this.userId,
      required this.matchId,
      required this.tipDate,
      required this.tipHome,
      required this.tipGuest,
      required this.joker});

  factory Tip.empty(UniqueID userId) {
    return Tip(
      id: UniqueID(),
      userId: userId,
      matchId: "",
      tipDate: DateTime.now(),
      tipHome: null,
      tipGuest: null,
      joker: false,
    );
  }

  Tip copyWith({
    UniqueID? id,
    UniqueID? userId,
    String? matchId,
    DateTime? tipDate,
    int? tipHome,
    int? tipGuest,
    bool? joker,
  }) {
    return Tip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      matchId: matchId ?? this.matchId,
      tipDate: tipDate ?? this.tipDate,
      tipHome: tipHome ?? this.tipHome,
      tipGuest: tipGuest ?? this.tipGuest,
      joker: joker ?? this.joker,
    );
  }
}
