// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';

import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:flutter_web/presentation/core/dialogs/match_dialog.dart';
import 'package:intl/intl.dart';

class MatchItem extends StatelessWidget {
  final CustomMatch match;
  final List<Team> teams;
  const MatchItem({
    Key? key,
    required this.match,
    required this.teams,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeTeam = teams.firstWhere(
      (team) => team.id == match.homeTeamId.value,
      orElse: () => Team.empty(),
    );
    final guestTeam = teams.firstWhere(
      (team) => team.id == match.guestTeamId.value,
      orElse: () => Team.empty(),
    );
    final themeData = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeData.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
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
                        height: 50,
                        width: 50,
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
                        height: 50,
                        width: 50,
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
                      _showUpdateMatchDialog(context, teams, match);
                    },
                  ),
                  const SizedBox(width: 8.0),
                  FancyIconButton(
                    icon: Icons.delete,
                    backgroundColor: themeData.colorScheme.onPrimary,
                    hoverColor: Colors.red,
                    borderColor: Colors.red,
                    callback: () {
                      _showDeleteMatchDialog(context, match);
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

  void _showDeleteMatchDialog(BuildContext context, CustomMatch match) {
    showDialog(
      barrierColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext newContext) {
            return MatchDialog(
              match: match,
              dialogText: "Match löschen",
              matchAction: MatchAction.delete,
            );
          },
        );
      },
    );
  }

  void _showUpdateMatchDialog(
      BuildContext context, List<Team> teams, CustomMatch match) {
    showDialog(
        barrierColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return Builder(
            builder: (BuildContext newContext) {
              return MatchDialog(
                teams: teams,
                dialogText: "Match bearbeiten",
                matchAction: MatchAction.update,
                match: match,
              );
            },
          );
        });
  }
}
