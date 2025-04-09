// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_web/domain/entities/id.dart';
import 'package:flutter_web/domain/entities/team.dart';


class AppUser {
  final UniqueID id;
  final String championId;
  final String username;
  final String email;
  final int rank;
  final int score;
  final int jokerSum;
  AppUser({
    required this.id,
    required this.championId,
    required this.username,
    required this.email,
    required this.rank,
    required this.score,
    required this.jokerSum,
  });

  factory AppUser.empty() {
    return AppUser(
      id: UniqueID(),
      championId: 'TBD',
      username: '',
      email: '',
      rank: 0,
      score: 0,
      jokerSum: 0,
    );
  }

  AppUser copyWith({
    UniqueID? id,
    String? championId,
    String? username,
    String? email,
    int? rank,
    int? score,
    int? jokerSum,
  }) {
    return AppUser(
      id: id ?? this.id,
      championId: championId ?? this.championId,
      username: username ?? this.username,
      email: email ?? this.email,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      jokerSum: jokerSum ?? this.jokerSum,
    );
  }
}
