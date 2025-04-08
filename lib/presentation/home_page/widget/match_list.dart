import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/add_button.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/core/dialogs/match_dialog.dart';

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
                return _buildMatchItem(context, match);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(BuildContext context, CustomMatch match) {
    final themeData = Theme.of(context);
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
          Text(
            '${match.homeTeamId.value} vs ${match.guestTeamId.value}',
            style: themeData.textTheme.bodyLarge,
          ),
          Text(
            '${match.homeScore ?? '-'} : ${match.guestScore ?? '-'}',
            style: themeData.textTheme.bodySmall,
          ),
          Text(
            'Spieltag: ${match.matchDay}',
            style: themeData.textTheme.bodySmall,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomButton(
                buttonText: 'Bearbeiten',
                backgroundColor: themeData.colorScheme.primaryContainer,
                borderColor: primaryDark,
                callback: () {
                  _showUpdateMatchDialog(context, teams, match);
                },
              ),
              const SizedBox(width: 8.0),
              CustomButton(
                buttonText: 'Löschen',
                backgroundColor: themeData.colorScheme.primaryContainer,
                borderColor: Colors.red,
                callback: () {
                  _showDeleteMatchDialog(context, match);
                },
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
          return MatchDialog(teams: teams, dialogText: "Neues Match", matchAction: MatchAction.create,);
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
          return MatchDialog(match: match, dialogText: "Match löschen", matchAction: MatchAction.delete,);
        },
      );
    },
  );
}

void _showUpdateMatchDialog(BuildContext context, List<Team> teams, CustomMatch match) {
  showDialog(
    barrierColor: Colors.transparent,
    context: context,
    builder: (BuildContext context) {
      return Builder(
        builder: (BuildContext newContext) {
          return MatchDialog(teams: teams, dialogText: "Match bearbeiten", matchAction: MatchAction.update, match: match,);
        },
      );
    },
  );
}
