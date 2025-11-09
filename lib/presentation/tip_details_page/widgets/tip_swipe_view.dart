import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/centered_constrained_wrapper.dart';
import 'package:flutter_web/presentation/tip_details_page/widgets/tip_details_community_tip_list.dart';
import 'package:flutter_web/presentation/tip_page/widgets/modern_tip_card.dart';

class TipsSwipeView extends StatefulWidget {
  final Map<String, List<Tip>> tips;
  final List<CustomMatch> matches;
  final List<Team> teams;
  final List<AppUser> users;
  final String userId;

  const TipsSwipeView({
    Key? key,
    required this.tips,
    required this.matches,
    required this.teams,
    required this.userId,
    required this.users,
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
      final userTips = widget.tips[widget.userId] ?? const <Tip>[];
      final tip = userTips.firstWhere(
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
    // CenterConstrainedWrapper sorgt für die gleiche Breite wie auf der Homepage
    return CenterConstrainedWrapper(
      child: ListView.separated(
        itemCount: widget.matches.length,
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        separatorBuilder: (context, index) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          final match = widget.matches[index];
          final userTips = widget.tips[widget.userId] ?? const <Tip>[];
          final tip = userTips.firstWhere(
            (t) => t.matchId == match.id,
            orElse: () => Tip.empty(widget.userId).copyWith(matchId: match.id),
          );

          final homeTeam = widget.teams.firstWhere((t) => t.id == match.homeTeamId, orElse: () => Team.empty());
          final guestTeam = widget.teams.firstWhere((t) => t.id == match.guestTeamId, orElse: () => Team.empty());

          final bloc = _tipFormBlocs[match.id];
          if (bloc == null) {
            return const SizedBox.shrink();
          }

          return BlocProvider<TipFormBloc>.value(
            value: bloc,
            child: TipCard(
              userId: widget.userId,
              tip: tip,
              homeTeam: homeTeam,
              guestTeam: guestTeam,
              match: match,
              footer: CommunityTipList(
                users: widget.users,
                allTips: widget.tips,
                match: match,
                currentUserId: widget.userId,
              ),
            ),
          );
        },
      ),
    );
  }
}
