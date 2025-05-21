import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'tip_item_content.dart';

class TipItem extends StatelessWidget {
  final String userId;
  final Tip? tip;
  final Team homeTeam;
  final Team guestTeam;
  final CustomMatch match;

  const TipItem({
    Key? key,
    required this.userId,
    required this.tip,
    required this.homeTeam,
    required this.guestTeam,
    required this.match,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TipItemContent(
      userId: userId,
      tip: tip,
      homeTeam: homeTeam,
      guestTeam: guestTeam,
      match: match,
    );
  }
}
