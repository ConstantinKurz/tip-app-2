import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
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
        children: [
          // Username + Tipps row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user.name,
                style: themeData.textTheme.displayLarge,
              ),
              TextButton.icon(
                onPressed: () {
                  Routemaster.of(context).push('/admin/user-tips/${user.id}');
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Tipps bearbeiten'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryDark,
                  backgroundColor:themeData.colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: primaryDark),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email:',
                      style: themeData.textTheme.bodyMedium,
                    ),
                    Text(
                      user.email,
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
                    const SizedBox(height: 8.0),
                    Text(
                      'Sechser: ${user.sixer}',
                      style: themeData.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FancyIconButton(
                icon: Icons.edit,
                backgroundColor: themeData.colorScheme.primaryContainer,
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
