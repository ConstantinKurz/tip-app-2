import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';

import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:flutter_web/presentation/core/dialogs/team_dialog.dart';

class TeamItem extends StatelessWidget {
  final Team team;

  const TeamItem({
    Key? key,
    required this.team,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeData.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                ClipOval(
                  child: Flag.fromString(
                    team.flagCode,
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16,),
                Text(
                  team.name,
                  style: themeData.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Tooltip(
                message: team.champion ? 'Champion' : 'Kein Champion',
                child: Icon(
                  Icons.star,
                  color: team.champion ? Colors.amber : Colors.grey,
                  size: 20.0,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Punkte: ${team.winPoints}',
                style: themeData.textTheme.bodyMedium,
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FancyIconButton(
                icon: Icons.edit,
                backgroundColor: themeData.colorScheme.onPrimary,
                hoverColor: primaryDark,
                borderColor: primaryDark,
                callback: () {
                  _showUpdateUserDialog(context, team);
                },
              ),
              const SizedBox(width: 8.0),
              FancyIconButton(
                icon: Icons.delete,
                backgroundColor: themeData.colorScheme.onPrimary,
                hoverColor: Colors.red,
                borderColor: Colors.red,
                callback: () {
                  print("Delete Team: ${team.name}");
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

  void _showUpdateUserDialog(
      BuildContext context, Team team) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Builder(
            builder: (BuildContext newContext) {
              return TeamDialog(
                team: team,
                dialogText: "Team bearbeiten",
                teamAction: TeamAction.update,
              );
            },
          );
        });}
