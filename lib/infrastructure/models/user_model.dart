// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web/domain/entities/id.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/infrastructure/models/team_model.dart';

class UserModel {
  final String id;
  final String championId;
  final String username;
  final String email;
  final int rank;
  final int score;
  final int jokerSum;

  UserModel({
    required this.id,
    required this.championId,
    required this.username,
    required this.email,
    required this.rank,
    required this.score,
    required this.jokerSum,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      championId: map['champion_id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      rank: map['rank'] as int,
      score: map['score'] as int,
      jokerSum: map['jokerSum'] as int,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data).copyWith(id: doc.id);
  }

  UserModel copyWith({
    String? id,
    String? championId,
    String? username,
    String? email,
    int? rank,
    int? score,
    int? jokerSum,
  }) {
    return UserModel(
      id: id ?? this.id,
      championId: championId ?? this.championId,
      username: username ?? this.username,
      email: email ?? this.email,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      jokerSum: jokerSum ?? this.jokerSum,
    );
  }

  AppUser toDomain() {
    return AppUser(
      id: UniqueID.fromUniqueString(id),
      championId: championId,
      username: username,
      email: email,
      rank: rank,
      score: score,
      jokerSum: jokerSum,
    );
  }

  factory UserModel.fromDomain(AppUser user) {
    return UserModel(
      id: user.id.value,
      championId: user.championId,
      username: user.username,
      email: user.email,
      rank: user.rank,
      score: user.score,
      jokerSum: user.jokerSum,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'champion_id': championId,
      'username': username,
      'email': email,
      'rank': rank,
      'score': score,
      'jokerSum': jokerSum,
    };
  }

  factory UserModel.empty(String id, String username, String email) {
    return UserModel(
        id: id,
        championId: 'TBD',
        username: username,
        email: email,
        rank: 0,
        score: 0,
        jokerSum: 0);
  }
}
