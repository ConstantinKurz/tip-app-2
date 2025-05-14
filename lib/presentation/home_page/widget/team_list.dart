// team_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart'; // Assuming this contains primaryDark etc.

import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:flutter_web/presentation/core/dialogs/team_dialog.dart';
import 'package:flutter_web/presentation/home_page/widget/team_item.dart';
// import 'package:flutter_web/presentation/core/dialogs/team_dialog.dart'; // You'll need a TeamDialog

class TeamList extends StatefulWidget {
  final List<Team> teams;

  const TeamList({Key? key, required this.teams}) : super(key: key);

  @override
  _TeamListState createState() => _TeamListState();
}

class _TeamListState extends State<TeamList> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    List<Team> filteredTeams = widget.teams.where((team) {
      final teamInfo =
          '${team.name} ${team.flagCode} ${team.winPoints} ${team.champion ? 'champion' : ''}' // Include relevant fields
              .toLowerCase();

      // Split the search text into individual terms
      final searchTerms = _searchText.toLowerCase().split(' ');

      bool allTermsMatch = true;
      for (final term in searchTerms) {
        if (term.isNotEmpty && !teamInfo.contains(term)) {
          allTermsMatch = false;
          break;
        }
      }
      return allTermsMatch;
    }).toList();

    return Center(
      child: Container(
        width: screenWidth * 0.4,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Teams', style: themeData.textTheme.headline6),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  width: screenWidth * .1,
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
                    callback: () => {_showAddTeamDialog(context)}),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
                child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredTeams.length,
              itemBuilder: (context, index) {
                final team = filteredTeams[index];
                return TeamItem(
                    team:
                        team); // Use the new TeamItem and pass the single team
              },
            )),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const TeamDialog(
          dialogText: "Neues Team",
          teamAction: TeamAction.create,
        );
      },
    );
  }
}
