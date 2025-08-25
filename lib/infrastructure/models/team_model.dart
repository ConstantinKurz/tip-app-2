// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web/domain/entities/team.dart';

class TeamModel {
  final String id;
  final String name;
  final String flagCode;
  final int winPoints;
  final bool champion;

  TeamModel({
    required this.id,
    required this.name,
    required this.flagCode,
    required this.winPoints,
    required this.champion,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'flag_code': flagCode,
      'win_points': winPoints,
      'champion': champion,
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    return TeamModel(
      id: (map['id'] ?? '') as String,
      name: map['name'] as String,
      flagCode: map['flag_code'] as String,
      winPoints: map['win_points'] as int,
      champion: map['champion'] as bool,
    );
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? flagCode,
    int? winPoints,
    bool? champion,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      flagCode: flagCode ?? this.flagCode,
      winPoints: winPoints ?? this.winPoints,
      champion: champion ?? this.champion,
    );
  }

  // only document on firestore has document id.
  factory TeamModel.fromFirestore(
      DocumentSnapshot doc) {
    Map<String, dynamic> dataMap = doc.data() as Map<String,dynamic>;
    return TeamModel.fromMap(dataMap).copyWith(id: doc.id);
  }

  Team toDomain() {
    return Team(
      id: id,
      name: name,
      flagCode: flagCode,
      winPoints: winPoints,
      champion: champion,
    );
  }

  factory TeamModel.fromDomain(Team team) {
    return TeamModel(
        id: team.id ,
        name: team.name,
        flagCode: team.flagCode,
        winPoints: team.winPoints,
        champion: team.champion);
  }
}
