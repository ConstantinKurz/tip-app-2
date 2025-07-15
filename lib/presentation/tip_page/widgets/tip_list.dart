import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_item_content.dart';

class TipList extends StatefulWidget {
  final String userId;
  final List<Tip> tips;
  final List<Team> teams;
  final List<CustomMatch> matches;

  const TipList({
    Key? key,
    required this.userId,
    required this.tips,
    required this.teams,
    required this.matches,
  }) : super(key: key);

  @override
  State<TipList> createState() => _TipListState();
}

class _TipListState extends State<TipList> {
  final Map<String, TipFormBloc> _tipFormBlocs = {};
  //TODO: add search
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
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: widget.matches.length,
                itemBuilder: (context, index) {
                  final match = widget.matches[index];

                  Tip? tip;
                  try {
                    tip = widget.tips
                        .firstWhere((tip) => tip.matchId == match.id);
                  } catch (_) {
                    tip = null;
                  }

                  final homeTeam = widget.teams
                      .firstWhere((team) => team.id == match.homeTeamId);
                  final guestTeam = widget.teams
                      .firstWhere((team) => team.id == match.guestTeamId);

                  final bloc = _tipFormBlocs[match.id]!;

                  return BlocProvider<TipFormBloc>.value(
                    value: bloc,
                    child: TipItemContent(
                      userId: widget.userId,
                      tip: tip,
                      homeTeam: homeTeam,
                      guestTeam: guestTeam,
                      match: match,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
