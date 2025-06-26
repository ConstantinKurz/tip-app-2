import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:flutter_web/presentation/core/dialogs/match_dialog.dart';
import 'package:flutter_web/presentation/admin_page/widget/match_item.dart';
import 'package:intl/intl.dart';

class MatchList extends StatefulWidget {
  final List<CustomMatch> matches;
  final List<Team> teams;

  const MatchList({Key? key, required this.matches, required this.teams})
      : super(key: key);

  @override
  _MatchListState createState() => _MatchListState();
}

class _MatchListState extends State<MatchList> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    List<CustomMatch> filteredMatches = widget.matches.where((match) {
      final homeTeam = widget.teams.firstWhere(
        (team) => team.id == match.homeTeamId,
        orElse: () => Team.empty(),
      );
      final guestTeam = widget.teams.firstWhere(
        (team) => team.id == match.guestTeamId,
        orElse: () => Team.empty(),
      );

      // Erstellen eines Strings, der alle relevanten Informationen des Matches enthält
      //TODO: hier muss es was besseres geben
      final matchInfo =
          '${homeTeam.name} ${guestTeam.name} Spieltag:${match.matchDay} '
                  '${match.homeScore ?? '-'}:${match.guestScore ?? '-'} '
                  '${DateFormat('dd.MM.yyyy HH:mm').format(match.matchDate)}'
              .toLowerCase();

      // Aufteilen des Suchtextes in einzelne Begriffe
      final searchTerms = _searchText.toLowerCase().split(' ');

      // Prüfen, ob alle Suchbegriffe in den Match-Informationen enthalten sind
      bool allTermsMatch = true;
      for (final term in searchTerms) {
        if (!matchInfo.contains(term)) {
          allTermsMatch = false;
          break;
        }
      }
      // add match to list if true
      return allTermsMatch;
    }).toList();

    return Center(
      child: Container(
        width: screenWidth * 0.5,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Matches', style: themeData.textTheme.headline6),
                const Spacer(),
                // Suchleiste
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
                        _searchText =
                            text; // Aktualisieren des Suchtextes bei jeder Änderung
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
                    callback: () => {
                          _showAddMatchDialog(context, widget.teams)
                        }),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
                child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredMatches.length,
              itemBuilder: (context, index) {
                final match = filteredMatches[index];
                return MatchItem(match: match, teams: widget.teams);
              },
            )),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  void _showAddMatchDialog(BuildContext context, List<Team> teams) {
    showDialog(
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
}
