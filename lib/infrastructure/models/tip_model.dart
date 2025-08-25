// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web/domain/entities/tip.dart';

class TipModel {
  final String id;
  final String? matchId;
  final DateTime tipDate;
  final int? tipHome;
  final int? tipGuest;
  final bool joker;
  final String userId;
  final int? points;
  TipModel(
      {required this.id,
      required this.matchId,
      required this.tipDate,
      required this.tipHome,
      required this.tipGuest,
      required this.joker,
      required this.userId,
      required this.points});

  TipModel copyWith(
      {String? id,
      String? matchId,
      DateTime? tipDate,
      int? tipHome,
      int? tipGuest,
      bool? joker,
      String? userId,
      int? points}) {
    return TipModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      tipDate: tipDate ?? this.tipDate,
      tipHome: tipHome ?? this.tipHome,
      tipGuest: tipGuest ?? this.tipGuest,
      joker: joker ?? this.joker,
      userId: userId ?? this.userId,
      points: points ?? this.points,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'matchId': matchId,
      'tipDate': tipDate,
      'tipHome': tipHome,
      'tipGuest': tipGuest,
      'joker': joker,
      'userId': userId,
      'points': points,
    };
  }

factory TipModel.fromMap(Map<String, dynamic> map) {
  return TipModel(
    id: (map['id'] ?? '') as String,
    matchId: map['matchId']?.toString(),
    tipDate: (map['tipDate'] as Timestamp).toDate(),
    tipHome: map['tipHome'] as int?,
    tipGuest: map['tipGuest'] as int?,
    joker: map['joker'] as bool? ?? false,
    userId: (map['userId'] ?? '') as String,
    points: map['points'] as int?,
  );
}


  factory TipModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TipModel.fromMap(data).copyWith(id: doc.id);
  }

  Tip toDomain() {
    return Tip(
      id: id,
      matchId: matchId,
      tipDate: tipDate,
      tipHome: tipHome,
      tipGuest: tipGuest,
      joker: joker,
      userId: userId,
      points: points
    );
  }

  factory TipModel.fromDomain(Tip tip) {
    return TipModel(
      id: tip.id,
      matchId: tip.matchId,
      tipDate: tip.tipDate,
      tipHome: tip.tipHome,
      tipGuest: tip.tipGuest,
      joker: tip.joker,
      userId: tip.userId,
      points: tip.points,
    );
  }
}
