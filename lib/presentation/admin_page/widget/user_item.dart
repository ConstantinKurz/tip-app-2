import 'package:flutter/material.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: themeData.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          // Username + Tipps row - responsive
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: themeData.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Routemaster.of(context)
                              .push('/admin/user-tips/${user.id}');
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Tipps bearbeiten'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              themeData.colorScheme.onPrimaryContainer,
                          backgroundColor:
                              themeData.colorScheme.primaryContainer,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(
                                color:
                                    themeData.colorScheme.onPrimaryContainer),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: themeData.textTheme.headlineMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        Routemaster.of(context)
                            .push('/admin/user-tips/${user.id}');
                      },
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Tipps bearbeiten',
                          overflow: TextOverflow.ellipsis),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            themeData.colorScheme.onPrimaryContainer,
                        backgroundColor: themeData.colorScheme.primaryContainer,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: themeData.colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email:',
                                style: themeData.textTheme.bodySmall,
                              ),
                              Text(
                                user.email,
                                style: themeData.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Admin:',
                                style: themeData.textTheme.bodySmall,
                              ),
                              Text(
                                user.admin ? 'Ja' : 'Nein',
                                style: themeData.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FancyIconButton(
                          icon: Icons.edit,
                          callback: () {
                            showDialog(
                              context: context,
                              builder: (_) => UserDialog(
                                  user: user,
                                  teams: teams,
                                  dialogText: 'Benutzerdaten bearbeiten',
                                  userAction: UserAction.update),
                            );
                          },
                          backgroundColor:
                              themeData.colorScheme.primaryContainer,
                          hoverColor: themeData.colorScheme.secondary,
                          borderColor: themeData.colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email:',
                            style: themeData.textTheme.bodySmall,
                          ),
                          Text(
                            user.email,
                            style: themeData.textTheme.bodyLarge,
                          ),
                          Text(
                            'Admin:',
                            style: themeData.textTheme.bodySmall,
                          ),
                          Text(
                            user.admin ? 'Ja' : 'Nein',
                            style: themeData.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    FancyIconButton(
                      icon: Icons.edit,
                      callback: () {
                        showDialog(
                          context: context,
                          builder: (_) => UserDialog(
                              user: user,
                              teams: teams,
                              dialogText: 'Benutzerdaten bearbeiten',
                              userAction: UserAction.update),
                        );
                      },
                      backgroundColor: themeData.colorScheme.primaryContainer,
                      hoverColor: themeData.colorScheme.secondary,
                      borderColor: themeData.colorScheme.secondary,
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
