// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_web/domain/entities/id.dart';
import 'package:flutter_web/domain/entities/match.dart';

class Tip {
  final UniqueID id;
  final UniqueID userId;
  final CustomMatch match;
  final DateTime tipDate;
  final int? tipHome;
  final int? tipGuest;
  final bool joker;
  Tip(
      {required this.id,
      required this.userId,
      required this.match,
      required this.tipDate,
      required this.tipHome,
      required this.tipGuest,
      required this.joker});

  factory Tip.empty(UniqueID userId) {
    return Tip(
      id: UniqueID(),
      userId: userId,
      match: CustomMatch.empty(),
      tipDate: DateTime.now(),
      tipHome: null,
      tipGuest: null,
      joker: false,
    );
  }

  Tip copyWith({
    UniqueID? id,
    UniqueID? userId,
    CustomMatch? match,
    DateTime? tipDate,
    int? tipHome,
    int? tipGuest,
    bool? joker,
  }) {
    return Tip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      match: match ?? this.match,
      tipDate: tipDate ?? this.tipDate,
      tipHome: tipHome ?? this.tipHome,
      tipGuest: tipGuest ?? this.tipGuest,
      joker: joker ?? this.joker,
    );
  }
}
