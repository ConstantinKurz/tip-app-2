import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_item.dart';

class TipList extends StatefulWidget {
  final String userId;
  final List<Tip> tips;
  final List<Team> teams;
  final List<CustomMatch> matches;

  const TipList(
      {Key? key,
      required this.userId,
      required this.tips,
      required this.teams,
      required this.matches})
      : super(key: key);

  @override
  _MatchListState createState() => _MatchListState();
}

class _MatchListState extends State<TipList> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // List<CustomMatch> filteredMatches = widget.matches.where((match) {
    //   final homeTeam = widget.teams.firstWhere(
    //     (team) => team.id == match.homeTeamId,
    //     orElse: () => Team.empty(),
    //   );
    //   final guestTeam = widget.teams.firstWhere(
    //     (team) => team.id == match.guestTeamId,
    //     orElse: () => Team.empty(),
    //   );

    //   // Erstellen eines Strings, der alle relevanten Informationen des Matches enthält
    //   //TODO: hier muss es was besseres geben
    //   final matchInfo =
    //       '${homeTeam.name} ${guestTeam.name} Spieltag:${match.matchDay} '
    //               '${match.homeScore ?? '-'}:${match.guestScore ?? '-'} '
    //               '${DateFormat('dd.MM.yyyy HH:mm').format(match.matchDate)}'
    //           .toLowerCase();

    //   // Aufteilen des Suchtextes in einzelne Begriffe
    //   final searchTerms = _searchText.toLowerCase().split(' ');

    // Prüfen, ob alle Suchbegriffe in den Match-Informationen enthalten sind
    //   bool allTermsMatch = true;
    //   for (final term in searchTerms) {
    //     if (!matchInfo.contains(term)) {
    //       allTermsMatch = false;
    //       break;
    //     }
    //   }
    //   // add match to list if true
    //   return allTermsMatch;
    // }).toList();

    return Center(
      child: Container(
        width: screenWidth * 0.5,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
                child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: widget.matches.length,
              itemBuilder: (context, index) {
                final match = widget.matches[index];

                Tip? tip;
                try {
                  tip =
                      widget.tips.firstWhere((tip) => tip.matchId == match.id);
                } catch (_) {
                  tip = null;
                }

                final homeTeam = widget.teams
                    .firstWhere((team) => team.id == match.homeTeamId);
                final guestTeam = widget.teams
                    .firstWhere((team) => team.id == match.guestTeamId);

                return BlocProvider<TipFormBloc>(
                  create: (_) {
                    final bloc = sl<TipFormBloc>();
                    if (tip != null) {
                      bloc.add(TipFormInitializedEvent(tip: tip));
                    }
                    return bloc;
                  },
                  child: TipItem(
                    userId: widget.userId,
                    tip: tip,
                    homeTeam: homeTeam,
                    guestTeam: guestTeam,
                    match: match,
                  ),
                );
              },
            )),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
