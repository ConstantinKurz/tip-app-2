// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';

import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:flutter_web/presentation/core/dialogs/user_dialog.dart';
import 'package:flutter_web/presentation/home_page/widget/user_item.dart';

class UserList extends StatefulWidget {
  final List<AppUser> users;
  final List<CustomMatch> matches;
  final List<Team> teams;
  const UserList({
    Key? key,
    required this.users,
    required this.matches,
    required this.teams,
  }) : super(key: key);

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  String _searchText = '';
  @override
  Widget build(BuildContext context) {
    List<AppUser> filteredUsers = widget.users.where((user) {
      // Erstellen eines Strings, der den Benutzernamen enthält
      final username = user.username.toLowerCase();
      // Aufteilen des Suchtextes in einzelne Begriffe
      final searchTerms = _searchText.toLowerCase().split(' ');
      // Prüfen, ob alle Suchbegriffe im Benutzernamen enthalten sind
      bool allTermsMatch = true;
      for (final term in searchTerms) {
        if (!username.contains(term)) {
          allTermsMatch = false;
          break;
        }
      }
      // Benutzer zur Liste hinzufügen, wenn alle Suchbegriffe übereinstimmen
      return allTermsMatch;
    }).toList();

    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Container(
        width: screenWidth * 0.6,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Tipper', style: themeData.textTheme.headline6),
                const Spacer(),
                // Suchleiste
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  width: screenWidth * .2,
                  child: TextField(
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Suche',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (text) {
                      setState(() {
                        _searchText = text;
                      });
                    },
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                FancyIconButton(
                    backgroundColor: themeData.colorScheme.primaryContainer,
                    hoverColor: primaryDark,
                    borderColor: primaryDark,
                    icon: Icons.add,
                    callback: () => _showAddUsersDialog(
                        context)),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
                child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return UserItem(user: user, teams: widget.teams);
              },
            )),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  void _showAddUsersDialog(
      BuildContext context) {
    showDialog(
      barrierColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext newContext) {
            return const UserDialog(
              dialogText: "Tipper hinzufügen",
              userAction: UserAction.create,
            );
          },
        );
      },
    );
  }
}
