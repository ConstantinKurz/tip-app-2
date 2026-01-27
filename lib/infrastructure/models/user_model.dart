import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web/domain/entities/user.dart';

class UserModel {
  final String id;
  final String championId;
  final String email;
  final String name;
  final int rank;
  final int score;
  final int jokerSum;
  final int sixer; 
  final bool admin; 

  UserModel({
    required this.id,
    required this.championId,
    required this.email,
    required this.name,
    required this.rank,
    required this.score,
    required this.jokerSum,
    required this.sixer,
    required this.admin, // <--- NEU
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
      admin: map['admin'] as bool? ?? false,
    );
  }

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
    bool? admin,
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
      admin: admin ?? this.admin, // <--- NEU
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
      admin: admin, // <--- NEU
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
      admin: user.admin, // <--- NEU
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
      'admin': admin,
    };
  }

  /// toJson für UserRepositoryImpl
  Map<String, dynamic> toJson() => toMap();

  /// fromJson für UserRepositoryImpl
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json);
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
      sixer: 0,
      admin: false,
    );
  }
}
