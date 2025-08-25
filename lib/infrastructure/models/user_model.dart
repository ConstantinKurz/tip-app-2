import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web/domain/entities/user.dart';

class UserModel {
  final String id; // Firestore doc-ID
  final String championId; // champion_id
  final String email; // email
  final String name; // name
  final int rank; // rank
  final int score; // score
  final int jokerSum; // jokerSum
  final int sixer; // mixer

  UserModel({
    required this.id,
    required this.championId,
    required this.email,
    required this.name,
    required this.rank,
    required this.score,
    required this.jokerSum,
    required this.sixer,
  });

  /// Konstruktor aus Map (z. B. aus Firestore-Daten ohne doc-ID)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      championId: map['champion_id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      rank: map['rank'] as int? ?? 0,
      score: map['score'] as int? ?? 0,
      jokerSum: map['jokerSum'] as int? ?? 0,
      sixer: map['sixer'] as int? ?? 0,
    );
  }

  /// Konstruktor direkt aus Firestore-Snapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap({...data, 'id': doc.id});
  }

  UserModel copyWith({
    String? id,
    String? championId,
    String? email,
    String? name,
    int? rank,
    int? score,
    int? jokerSum,
    int? sixer,
  }) {
    return UserModel(
      id: id ?? this.id,
      championId: championId ?? this.championId,
      email: email ?? this.email,
      name: name ?? this.name,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      jokerSum: jokerSum ?? this.jokerSum,
      sixer: sixer ?? this.sixer,
    );
  }

  /// Mapping zur Domain-Entity AppUser
  AppUser toDomain() {
    return AppUser(
      id: id,
      championId: championId,
      email: email,
      name: name,
      rank: rank,
      score: score,
      jokerSum: jokerSum,
      sixer: sixer,
    );
  }

  /// Mapping von Domain-Entity zu Model (für Saves)
  factory UserModel.fromDomain(AppUser user) {
    return UserModel(
      id: user.id,
      championId: user.championId,
      email: user.email,
      name: user.name,
      rank: user.rank,
      score: user.score,
      jokerSum: user.jokerSum,
      sixer: user.sixer,
    );
  }

  /// In Map für Firestore speichern
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'champion_id': championId,
      'email': email,
      'name': name,
      'rank': rank,
      'score': score,
      'jokerSum': jokerSum,
      'sixer': sixer,
    };
  }

    factory UserModel.empty(String username, String email) {
    return UserModel(
        id: username,
        championId: 'TBD',
        name: username,
        email: email,
        rank: 0,
        score: 0,
        jokerSum: 0,
        sixer: 0);
  }
}
