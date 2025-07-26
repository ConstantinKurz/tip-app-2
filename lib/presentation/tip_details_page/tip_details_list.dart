import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_item_content.dart';
import 'package:intl/intl.dart';

class TipDetailList extends StatelessWidget {
  final String userId;
  final List<Tip> tips;
  final List<Team> teams;
  final List<CustomMatch> matches;
  final bool showSearchBar;

  const TipDetailList({
    Key? key,
    required this.userId,
    required this.tips,
    required this.teams,
    required this.matches,
    required this.showSearchBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final filteredMatches = showSearchBar
        ? _filteredTips(matches, teams, _searchText(context))
        : matches;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (showSearchBar) _buildSearchBar(context),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: filteredMatches.map((match) {
              final tip = tips.firstWhere(
                (t) => t.matchId == match.id,
                orElse: () => Tip.empty(userId).copyWith(matchId: match.id),
              );
              final homeTeam =
                  teams.firstWhere((t) => t.id == match.homeTeamId);
              final guestTeam =
                  teams.firstWhere((t) => t.id == match.guestTeamId);

              final bloc = sl<TipFormBloc>()..add(TipFormInitializedEvent(tip: tip));

              return SizedBox(
                width: isMobile ? double.infinity : 300,
                child: BlocProvider<TipFormBloc>.value(
                  value: bloc,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TipItemContent(
                        userId: userId,
                        tip: tip,
                        homeTeam: homeTeam,
                        guestTeam: guestTeam,
                        match: match,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final controller = TextEditingController();
    controller.text = _searchText(context);
    return TextField(
      controller: controller,
      onChanged: (text) {
        context.findAncestorStateOfType<State<StatefulWidget>>()?.setState(() {
          searchTexts[context.hashCode] = text;
        });
      },
      decoration: InputDecoration(
        hintText: 'Suche...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }

  static final Map<int, String> searchTexts = {};

  String _searchText(BuildContext context) =>
      searchTexts[context.hashCode] ?? '';

  List<CustomMatch> _filteredTips(List<CustomMatch> matches, List<Team> teams, String searchText) {
    final terms = searchText.toLowerCase().split(' ');
    return matches.where((match) {
      final homeTeam = teams.firstWhere((t) => t.id == match.homeTeamId, orElse: () => Team.empty());
      final guestTeam = teams.firstWhere((t) => t.id == match.guestTeamId, orElse: () => Team.empty());
      final info = '${homeTeam.name} ${guestTeam.name} Spieltag:${match.matchDay} '
          '${match.homeScore ?? '-'}:${match.guestScore ?? '-'} '
          '${DateFormat('dd.MM.yyyy HH:mm').format(match.matchDate)}'
          .toLowerCase();
      return terms.every((term) => info.contains(term));
    }).toList();
  }
}
