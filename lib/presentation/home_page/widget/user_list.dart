// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';

import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
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
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Container(
        width: screenWidth * 0.8,
        padding: const EdgeInsets.all(16.0),
        // decoration: BoxDecoration(
        //   // color: themeData.colorScheme.primaryContainer,
        //   borderRadius: BorderRadius.circular(12.0),
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.grey.withOpacity(0.3),
        //       spreadRadius: 2,
        //       blurRadius: 5,
        //       offset: const Offset(0, 3),
        //     ),
        //   ],
        // ),
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
                    decoration: const InputDecoration(
                      hintText: 'Suche',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (text) {
                      setState(() {
                        null;
                        // _searchText =
                        //     text; // Aktualisieren des Suchtextes bei jeder Änderung
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
                    callback: () => _showAddUsersDialog(context, widget.matches, widget.teams)),
              ],
            ),
            const SizedBox(height: 8.0),
            ListView.builder(
              shrinkWrap: true,
              itemCount:
                  widget.users.length,
              itemBuilder: (context, index) {
                final user = widget.users[index];
                return UserItem(user: user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUsersDialog(BuildContext context,List<CustomMatch> matches, List<Team> teams) {
    showDialog(
      barrierColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext newContext) {
            return Container();
          },
        );
      },
    );
  }
}
