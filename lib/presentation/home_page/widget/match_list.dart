import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/add_button.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:flutter_web/presentation/core/dialogs/match_dialog.dart';
import 'package:flag/flag.dart';

class MatchList extends StatelessWidget {
  final List<CustomMatch> matches;
  final List<Team> teams;

  const MatchList({Key? key, required this.matches, required this.teams})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Matches:', style: Theme.of(context).textTheme.headline6),
              AddButton(onPressed: () => _showAddMatchDialog(context, teams)),
            ],
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final homeTeam = teams.firstWhere(
                  (team) => team.id == match.homeTeamId.value,
                  orElse: () => Team.empty(),
                );
                final guestTeam = teams.firstWhere(
                  (team) => team.id == match.guestTeamId.value,
                  orElse: () => Team.empty(),
                );

                return _buildMatchItem(context, match, homeTeam, guestTeam);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(
      BuildContext context, CustomMatch match, Team homeTeam, Team guestTeam) {
    final themeData = Theme.of(context);
    print(homeTeam.flagCode);
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeData.colorScheme.primaryContainer,
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
            'Spieltag: ${match.matchDay}, ${match.matchDate}',
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
                    Flag.fromString(
                      homeTeam.flagCode,
                      height: 24,
                      width: 36,
                      fit: BoxFit.cover,
                      borderRadius: 8,
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
                    Flag.fromString(
                      guestTeam.flagCode,
                      height: 24,
                      width: 36,
                      fit: BoxFit.cover,
                      borderRadius: 8,
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
                    backgroundColor: themeData.colorScheme.primaryContainer,
                    hoverColor: primaryDark,
                    borderColor: primaryDark,
                    callback: () {
                      _showUpdateMatchDialog(context, teams, match);
                    },
                  ),
                  const SizedBox(width: 8.0),
                  FancyIconButton(
                    icon: Icons.delete,
                    backgroundColor: themeData.colorScheme.primaryContainer,
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
}

void _showAddMatchDialog(BuildContext context, List<Team> teams) {
  showDialog(
    barrierColor: Colors.transparent,
    context: context,
    builder: (BuildContext context) {
      return Builder(
        builder: (BuildContext newContext) {
          return MatchDialog(
            teams: teams,
            dialogText: "Neues Match",
            matchAction: MatchAction.create,
          );
        },
      );
    },
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
    },
  );
}
