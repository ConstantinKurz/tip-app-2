import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_item_content.dart';

class TipsSwipeView extends StatefulWidget {
  final List<Tip> tips;
  final List<CustomMatch> matches;
  final List<Team> teams;
  final String userId;

  const TipsSwipeView({
    Key? key,
    required this.tips,
    required this.matches,
    required this.teams,
    required this.userId,
  }) : super(key: key);

  @override
  State<TipsSwipeView> createState() => _TipsSwipeViewState();
}

class _TipsSwipeViewState extends State<TipsSwipeView> {
  final Map<String, TipFormBloc> _tipFormBlocs = {};

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
    for (var bloc in _tipFormBlocs.values) {
      bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: widget.matches.length,
      itemBuilder: (context, index) {
        final match = widget.matches[index];
        final tip = widget.tips.firstWhere(
          (t) => t.matchId == match.id,
          orElse: () => Tip.empty(widget.userId).copyWith(matchId: match.id),
        );

        final homeTeam =
            widget.teams.firstWhere((t) => t.id == match.homeTeamId);
        final guestTeam =
            widget.teams.firstWhere((t) => t.id == match.guestTeamId);

        final bloc = _tipFormBlocs[match.id]!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: BlocProvider<TipFormBloc>.value(
            value: bloc,
            child: Column(
              children: [
                TipItemContent(
                  userId: widget.userId,
                  tip: tip,
                  homeTeam: homeTeam,
                  guestTeam: guestTeam,
                  match: match,
                ),
                const SizedBox(height: 24),
                //Expanded(
                //child: OtherPlayersTipCards(matchId: match.id),
                //)
              ],
            ),
          ),
        );
      },
    );
  }
}
