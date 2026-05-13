import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';

import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:flutter_web/presentation/admin_page/widget/team_item.dart';
import 'package:routemaster/routemaster.dart';

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
    final isMobile = screenWidth < 800;
    final double containerWidth =
        isMobile ? screenWidth * 0.95 : screenWidth * 0.4;
    final double searchFieldWidth =
        isMobile ? screenWidth * 0.3 : screenWidth * 0.1;

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
        width: containerWidth,
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Teams', style: themeData.textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: TextField(
                                cursorColor: Colors.white,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Suche',
                                  prefixIcon: Icon(Icons.search),
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8),
                                ),
                                onChanged: (text) {
                                  setState(() {
                                    _searchText = text;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FancyIconButton(
                            backgroundColor:
                                themeData.colorScheme.primaryContainer,
                            hoverColor: primaryDark,
                            borderColor: primaryDark,
                            icon: Icons.add,
                            callback: () => _showAddTeamDialog(context),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Text('Teams', style: themeData.textTheme.headlineLarge),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        width: searchFieldWidth,
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
                          backgroundColor:
                              themeData.colorScheme.primaryContainer,
                          hoverColor: primaryDark,
                          borderColor: primaryDark,
                          icon: Icons.add,
                          callback: () => _showAddTeamDialog(context)),
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
    Routemaster.of(context).push('/admin/team/create');
  }
}
