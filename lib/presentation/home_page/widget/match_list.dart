import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:flutter_web/presentation/core/dialogs/match_dialog.dart';
import 'package:flag/flag.dart';
import 'package:flutter_web/presentation/home_page/widget/match_item.dart';
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

    List<CustomMatch> filteredMatches = widget.matches.where((match) {
      final homeTeam = widget.teams.firstWhere(
        (team) => team.id == match.homeTeamId.value,
        orElse: () => Team.empty(),
      );
      final guestTeam = widget.teams.firstWhere(
        (team) => team.id == match.guestTeamId.value,
        orElse: () => Team.empty(),
      );

      // Erstellen eines Strings, der alle relevanten Informationen des Matches enthält
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

      return allTermsMatch;
    }).toList();

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: themeData.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12.0),
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
            Row(
              children: [
                Text('Matches:', style: themeData.textTheme.headline6),
                const Spacer(),
                // Suchleiste
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  width: 350,
                  child: TextField(
                    cursorColor: Colors.white,
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
                    callback: () => _showAddMatchDialog(context, widget.teams)),
              ],
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount:
                    filteredMatches.length, // Verwenden der gefilterten Liste
                itemBuilder: (context, index) {
                  final match = filteredMatches[index];
                  // final homeTeam = widget.teams.firstWhere(
                  //   (team) => team.id == match.homeTeamId.value,
                  //   orElse: () => Team.empty(),
                  // );
                  // final guestTeam = widget.teams.firstWhere(
                  //   (team) => team.id == match.guestTeamId.value,
                  //   orElse: () => Team.empty(),
                  // );
                  return MatchItem(match: match, teams: widget.teams);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMatchDialog(BuildContext context, List<Team> teams) {
    showDialog(
      barrierColor: Colors.transparent,
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
