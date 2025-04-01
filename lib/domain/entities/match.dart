// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_web/domain/entities/id.dart';
import 'package:flutter_web/domain/entities/team.dart';

class CustomMatch {
  final UniqueID id;
  final UniqueID homeTeamId;
  final UniqueID guestTeamId;
  final DateTime matchDate;
  final int matchDay;
  final int? homeScore;
  final int? guestScore;

  CustomMatch({
    required this.id,
    required this.homeTeamId,
    required this.guestTeamId,
    required this.matchDate,
    required this.matchDay,
    required this.homeScore,
    required this.guestScore,
  }) : assert(matchDay >= 0 && matchDay <= 6, 'Matchday must be between 0 and 6');

  CustomMatch copyWith({
    UniqueID? id,
    UniqueID? homeTeamId,
    UniqueID? guestTeamId,
    DateTime? matchDate,
    int? matchDay,
    int? homeScore,
    int? guestScore,
  }) {
    return CustomMatch(
      id: id ?? this.id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      guestTeamId: guestTeamId ?? this.guestTeamId,
      matchDate: matchDate ?? this.matchDate,
      matchDay: matchDay ?? this.matchDay,
      homeScore: homeScore ?? this.homeScore,
      guestScore: guestScore ?? this.guestScore,
    );
  }

  factory CustomMatch.empty({
    UniqueID? id,
    UniqueID? homeTeamId,
    UniqueID? guestTeamId,
    DateTime? matchDate,
    int? matchDay,
    int? homeScore,
    int? guestScore,
  }) {
    return CustomMatch(
      id: id ?? UniqueID(),
      homeTeamId: homeTeamId ?? UniqueID.fromUniqueString(Team.empty().id),
      guestTeamId: guestTeamId ?? UniqueID.fromUniqueString(Team.empty().id),
      matchDate: matchDate ?? DateTime.now(),
      matchDay: matchDay ?? 0,
      homeScore: homeScore,
      guestScore: guestScore,
    );
  }
}
