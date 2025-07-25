import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_list.dart';

class UpcomingTipSection extends StatelessWidget {
  final String userId;

  const UpcomingTipSection({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
      builder: (context, matchState) {
        return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
          builder: (context, teamState) {
            return BlocBuilder<TipControllerBloc, TipControllerState>(
              builder: (context, tipState) {
                if (matchState is MatchesControllerLoaded &&
                    teamState is TeamsControllerLoaded &&
                    tipState is TipControllerLoaded) {
                  final themeData = Theme.of(context);
                  final now = DateTime.now();

                  final allMatches = matchState.matches.toList();

                  allMatches.sort((a, b) =>
                      (a.matchDate.difference(now).inSeconds).abs().compareTo(
                            (b.matchDate.difference(now).inSeconds).abs(),
                          ));

                  final closestThreeMatches = allMatches.take(3).toList();
                  final userTips = tipState.tips[userId] ?? [];

                  return Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_soccer,
                              color: themeData.colorScheme.onPrimary, size: 30),
                          const SizedBox(width: 12),
                          Text('Die Aktuellen Spiele',
                              style: themeData.textTheme.headlineSmall),
                        ],
                      ),
                      TipList(
                        userId: userId,
                        tips: userTips,
                        matches: closestThreeMatches,
                        teams: teamState.teams,
                        showSearchBar: false,
                      ),
                    ],
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        );
      },
    );
  }
}
