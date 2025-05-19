import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:flutter_web/presentation/core/buttons/more_button.dart';
import 'package:flutter_web/presentation/core/dialogs/user_dialog.dart';
import 'package:routemaster/routemaster.dart';

class UserItem extends StatelessWidget {
  final AppUser user;
  final List<Team> teams;

  const UserItem({Key? key, required this.user, required this.teams})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        children: [
          // Username + Tipps row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user.username,
                style: themeData.textTheme.displayLarge,
              ),
              HoverLinkButton(
                label: 'Tipps',
                color: primaryDark,
                onTap: () {
                  Routemaster.of(context).push('/tips/${user.username}');
                },
              ),
            ],
          ),
          // const SizedBox(height: 16.0),

          // Edit button aligned right
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     FancyIconButton(
          //       icon: Icons.edit,
          //       backgroundColor: themeData.colorScheme.onPrimary,
          //       hoverColor: primaryDark,
          //       borderColor: primaryDark,
          //       callback: () {
          //         _showUpdateUserDialog(context, teams, user);
          //       },
          //     ),
          //   ],
          // ),
          // User details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email: ${user.email}',
                      style: themeData.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Rang: ${user.rank}',
                      style: themeData.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Punkte: ${user.score}',
                      style: themeData.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Champion: ${user.championId}',
                      style: themeData.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Joker: ${user.jokerSum}',
                      style: themeData.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FancyIconButton(
                icon: Icons.edit,
                backgroundColor: themeData.colorScheme.onPrimary,
                hoverColor: primaryDark,
                borderColor: primaryDark,
                callback: () {
                  _showUpdateUserDialog(context, teams, user);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateUserDialog(
      BuildContext context, List<Team> teams, AppUser user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext newContext) {
            return UserDialog(
              teams: teams,
              dialogText: "Tipper bearbeiten",
              userAction: UserAction.update,
              user: user,
            );
          },
        );
      },
    );
  }
}
