// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web/domain/entities/id.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/infrastructure/models/match_model.dart';

class TipModel {
  final String id;
  final MatchModel match;
  final DateTime tipDate;
  final int? tipHome;
  final int? tipGuest;
  final bool joker;
  final String userId;  // Referenz auf die Benutzer-ID

  TipModel({
    required this.id,
    required this.match,
    required this.tipDate,
    required this.tipHome,
    required this.tipGuest,
    required this.joker,
    required this.userId,
  });

  TipModel copyWith({
    String? id,
    MatchModel? match,
    DateTime? tipDate,
    int? tipHome,
    int? tipGuest,
    bool? joker,
    String? userId,
  }) {
    return TipModel(
      id: id ?? this.id,
      match: match ?? this.match,
      tipDate: tipDate ?? this.tipDate,
      tipHome: tipHome ?? this.tipHome,
      tipGuest: tipGuest ?? this.tipGuest,
      joker: joker ?? this.joker,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'match': match.toMap(),
      'tipDate': tipDate.millisecondsSinceEpoch,
      'tipHome': tipHome,
      'tipGuest': tipGuest,
      'joker': joker,
      'userId': userId,
    };
  }

  factory TipModel.fromMap(Map<String, dynamic> map) {
    return TipModel(
      id: map['id'] as String,
      match: MatchModel.fromMap(map['match'] as Map<String, dynamic>),
      tipDate: (map['tipDate'] as Timestamp).toDate(),
      tipHome: map['tipHome'] as int?,
      tipGuest: map['tipGuest'] as int?,
      joker: map['joker'] as bool,
      userId: map['userId'] as String,
    );
  }

  factory TipModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TipModel.fromMap(data).copyWith(id: doc.id);
  }

  Tip toDomain() {
    return Tip(
      id: UniqueID.fromUniqueString(id),
      match: match.toDomain(),
      tipDate: tipDate,
      tipHome: tipHome,
      tipGuest: tipGuest,
      joker: joker,
      userId: UniqueID.fromUniqueString(userId),
    );
  }

  factory TipModel.fromDomain(Tip tip) {
    return TipModel(
      id: tip.id.value,
      match: MatchModel.fromDomain(tip.match),
      tipDate: tip.tipDate,
      tipHome: tip.tipHome,
      tipGuest: tip.tipGuest,
      joker: tip.joker,
      userId: tip.id.toString(),
    );
  }
}

