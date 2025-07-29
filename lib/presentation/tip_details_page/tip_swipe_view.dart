import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/tip_details_page/tip_details_ranking_user_list.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_item_content.dart';

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
      final tip = widget.tips[widget.userId]?.firstWhere(
        (t) => t.matchId == match.id,
        orElse: () => Tip.empty(widget.userId).copyWith(matchId: match.id),
      );

      if (!_tipFormBlocs.containsKey(match.id)) {
        final bloc = sl<TipFormBloc>();
        bloc.add(TipFormInitializedEvent(tip: tip!));
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
      controller: PageController(viewportFraction: 0.6),
      itemBuilder: (context, index) {
        final match = widget.matches[index];
        final tip = widget.tips[widget.userId]?.firstWhere(
          (t) => t.matchId == match.id && t.userId == widget.userId,
          orElse: () => Tip.empty(widget.userId).copyWith(matchId: match.id),
        );
    
        final homeTeam =
            widget.teams.firstWhere((t) => t.id == match.homeTeamId);
        final guestTeam =
            widget.teams.firstWhere((t) => t.id == match.guestTeamId);
        final bloc = _tipFormBlocs[match.id]!;
    
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: BlocProvider<TipFormBloc>.value(
            value: bloc,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TipItemContent(
                    userId: widget.userId,
                    tip: tip,
                    homeTeam: homeTeam,
                    guestTeam: guestTeam,
                    match: match,
                    bottomContent: Column(
                      children: [
                        const Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                        TipDetailsRankingUserList(
                          users: widget.users,
                          teams: widget.teams,
                          currentUser: widget.userId,
                          tips: widget.tips,
                          match: match,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
