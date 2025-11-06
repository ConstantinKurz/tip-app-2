import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_item_content.dart';
import 'package:intl/intl.dart';

class TipList extends StatefulWidget {
  final String userId;
  final List<Tip> tips;
  final List<Team> teams;
  final List<CustomMatch> matches;
  final bool showSearchBar;

  const TipList(
      {Key? key,
      required this.userId,
      required this.tips,
      required this.teams,
      required this.matches,
      required this.showSearchBar})
      : super(key: key);

  @override
  State<TipList> createState() => _TipListState();
}

class _TipListState extends State<TipList> {
  final Map<String, TipFormBloc> _tipFormBlocs = {};
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
  }

  void _initializeBlocs() {
    for (final match in widget.matches) {
      final tip = widget.tips.firstWhere(
        (t) => t.matchId == match.id,
        orElse: () => Tip.empty(widget.userId).copyWith(matchId: match.id),
      );

      if (!_tipFormBlocs.containsKey(match.id)) {
        final bloc = sl<TipFormBloc>();
        bloc.add(TipFormInitializedEvent(tip: tip));
        _tipFormBlocs[match.id] = bloc;
      }
    }
  }

  @override
  void dispose() {
    for (final bloc in _tipFormBlocs.values) {
      bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final displayedTips = widget.showSearchBar
        ? _filteredTips(widget.matches, widget.teams, _searchText)
        : widget.matches;

    return Center(
      child: Container(
        width: screenWidth * 0.5,
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                const Spacer(),
                if (widget.showSearchBar)
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
              ],
            ),
            const SizedBox(height: 16.0),
            ...displayedTips.map((match) {
              final tip = widget.tips.firstWhere(
                (t) => t.matchId == match.id,
                orElse: () =>
                    Tip.empty(widget.userId).copyWith(matchId: match.id),
              );

              final homeTeam = widget.teams.firstWhere(
                (t) => t.id == match.homeTeamId,
                orElse: () => Team.empty(),
              );
              final guestTeam = widget.teams.firstWhere(
                (t) => t.id == match.guestTeamId,
                orElse: () => Team.empty(),
              );

              final bloc = _tipFormBlocs[match.id];
              if (bloc == null) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: BlocProvider<TipFormBloc>.value(
                  value: bloc,
                  child: TipItemContent(
                    userId: widget.userId,
                    tip: tip,
                    homeTeam: homeTeam,
                    guestTeam: guestTeam,
                    match: match,
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

List<CustomMatch> _filteredTips(
    List<CustomMatch> matches, List<Team> teams, String searchText) {
  List<CustomMatch> filteredTips = matches.where((match) {
    final homeTeam = teams.firstWhere(
      (team) => team.id == match.homeTeamId,
      orElse: () => Team.empty(),
    );
    final guestTeam = teams.firstWhere(
      (team) => team.id == match.guestTeamId,
      orElse: () => Team.empty(),
    );

    final matchInfo =
        '${homeTeam.name} ${guestTeam.name} Spieltag:${match.matchDay} '
                '${match.homeScore ?? '-'}:${match.guestScore ?? '-'} '
                '${DateFormat('dd.MM.yyyy HH:mm').format(match.matchDate)}'
            .toLowerCase();

    final searchTerms = searchText.toLowerCase().split(' ');

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

  return filteredTips;
}
