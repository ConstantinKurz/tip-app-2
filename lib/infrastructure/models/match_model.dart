import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_web/domain/entities/id.dart';
import 'package:flutter_web/domain/entities/match.dart'; // Adjust import path as per your project structure


class MatchModel {
  final String id;
  final String homeTeamId;
  final String guestTeamId;
  final DateTime matchDate;
  final int matchDay;
  final int? homeScore;
  final int? guestScore;

  MatchModel({
    required this.id,
    required this.homeTeamId,
    required this.guestTeamId,
    required this.matchDate,
    required this.matchDay,
    required this.homeScore,
    required this.guestScore,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'homeTeamId': homeTeamId,
      'guestTeamId': guestTeamId,
      'matchDate': matchDate,
      'matchDay': matchDay,
      'homeScore': homeScore,
      'guestScore': guestScore,
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {

    return MatchModel(
      id: '',
      homeTeamId: map['homeTeamId'] as String,
      guestTeamId: map['guestTeamId'] as String,
      matchDate: (map['matchDate'] as Timestamp).toDate(),
      matchDay: map['matchDay'] as int,
      homeScore: map['homeScore'] as int?,
      guestScore: map['guestScore'] as int?,
    );
  }


  // Only document on Firestore has document id.
  factory MatchModel.fromFirestore(DocumentSnapshot doc)  {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MatchModel.fromMap(data).copyWith(id: doc.id);
  }

  CustomMatch toDomain() {
    return CustomMatch(
      id: UniqueID.fromUniqueString(id),
      homeTeamId: UniqueID.fromUniqueString(homeTeamId),
      guestTeamId: UniqueID.fromUniqueString(guestTeamId),
      matchDate: matchDate,
      matchDay: matchDay,
      homeScore: homeScore,
      guestScore: guestScore,
    );
  }

  MatchModel copyWith({
    String? id,
    String? homeTeamId,
    String? guestTeamId,
    DateTime? matchDate,
    int? matchDay,
    int? homeScore,
    int? guestScore,
  }) {
    return MatchModel(
      id: id ?? this.id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      guestTeamId: guestTeamId ?? this.guestTeamId,
      matchDate: matchDate ?? this.matchDate,
      matchDay: matchDay ?? this.matchDay,
      homeScore: homeScore ?? this.homeScore,
      guestScore: guestScore ?? this.guestScore,
    );
  }

  factory MatchModel.fromDomain(CustomMatch match) {
    return MatchModel(
        id: match.id.value,
        homeTeamId: match.homeTeamId.value,
        guestTeamId: match.guestTeamId.value,
        matchDate: match.matchDate,
        matchDay: match.matchDay,
        homeScore: match.homeScore,
        guestScore: match.guestScore);
  }
}
