import 'package:dartz/dartz.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:intl/intl.dart';

class TipItem extends StatelessWidget {
  final Tip tip;
  final List<Team> teams;
  final List<CustomMatch> matches;
  const TipItem(
      {Key? key, required this.tip, required this.teams, required this.matches})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final match = matches.firstWhere((match) => match.id == tip.matchId);
    final homeTeam = teams.firstWhere(
      (team) => team.id == match.homeTeamId,
      orElse: () => Team.empty(),
    );
    final guestTeam = teams.firstWhere(
      (team) => team.id == match.guestTeamId,
      orElse: () => Team.empty(),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeData.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spieltag und Spielzeit oben links
          Text(
            'Spieltag:${match.matchDay}, ${DateFormat('dd.MM.yyyy HH:mm').format(match.matchDate)}',
            style: themeData.textTheme.bodySmall,
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              const Spacer(),
              // Heimteam
              Expanded(
                child: Column(
                  children: [
                    ClipOval(
                      child: Flag.fromString(
                        homeTeam.flagCode,
                        height: 30,
                        width: 30,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Text(
                      homeTeam.name,
                      style: themeData.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              // Heim- und Gastscore nebeneinander
              Text(
                '${match.homeScore ?? '-'} : ${match.guestScore ?? '-'}',
                style: themeData.textTheme.bodyLarge,
              ),
              const SizedBox(width: 16.0),
              // Gastteam
              Expanded(
                child: Column(
                  children: [
                    ClipOval(
                      child: Flag.fromString(
                        guestTeam.flagCode,
                        height: 30,
                        width: 30,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Text(
                      guestTeam.name,
                      style: themeData.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  FancyIconButton(
                    icon: Icons.edit,
                    backgroundColor: themeData.colorScheme.onPrimary,
                    hoverColor: primaryDark,
                    borderColor: primaryDark,
                    callback: () {
                      // _showUpdateMatchDialog(context, teams, match);
                    },
                  ),
                  const SizedBox(width: 8.0),
                  FancyIconButton(
                    icon: Icons.delete,
                    backgroundColor: themeData.colorScheme.onPrimary,
                    hoverColor: Colors.red,
                    borderColor: Colors.red,
                    callback: () {
                      // _showDeleteMatchDialog(context, match);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
