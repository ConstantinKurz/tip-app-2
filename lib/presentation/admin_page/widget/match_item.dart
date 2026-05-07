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
      (team) => team.id == match.homeTeamId,
      orElse: () => Team.empty(),
    );
    final guestTeam = teams.firstWhere(
      (team) => team.id == match.guestTeamId,
      orElse: () => Team.empty(),
    );
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final flagSize = isMobile ? 24.0 : 30.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: themeData.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Spieltag und Spielzeit
          Text(
            'Spieltag:${match.matchDay}, ${DateFormat('dd.MM.yyyy HH:mm').format(match.matchDate)}',
            style: themeData.textTheme.bodySmall,
          ),
          const SizedBox(height: 12.0),

          isMobile
              ? Column(
                  children: [
                    // Home Team + Flag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Flag.fromString(
                            homeTeam.flagCode,
                            height: flagSize,
                            width: flagSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            homeTeam.name,
                            style: themeData.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Score
                    Text(
                      '${match.homeScore ?? '-'} : ${match.guestScore ?? '-'}',
                      style: themeData.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Guest Team + Flag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Flag.fromString(
                            guestTeam.flagCode,
                            height: flagSize,
                            width: flagSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            guestTeam.name,
                            style: themeData.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FancyIconButton(
                          icon: Icons.edit,
                          backgroundColor:
                              themeData.colorScheme.primaryContainer,
                          hoverColor: primaryDark,
                          borderColor: primaryDark,
                          callback: () {
                            _showUpdateMatchDialog(context, teams, match);
                          },
                        ),
                        const SizedBox(width: 8.0),
                        FancyIconButton(
                          icon: Icons.delete,
                          backgroundColor:
                              themeData.colorScheme.primaryContainer,
                          hoverColor: Colors.red,
                          borderColor: Colors.red,
                          callback: () {
                            _showDeleteMatchDialog(context, match);
                          },
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
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
                          backgroundColor:
                              themeData.colorScheme.primaryContainer,
                          hoverColor: primaryDark,
                          borderColor: primaryDark,
                          callback: () {
                            _showUpdateMatchDialog(context, teams, match);
                          },
                        ),
                        const SizedBox(width: 8.0),
                        FancyIconButton(
                          icon: Icons.delete,
                          backgroundColor:
                              themeData.colorScheme.primaryContainer,
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
