import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/injections.dart';
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
                  final upcomingMatches = matchState.matches
                      .where((m) => m.matchDate.isAfter(DateTime.now()))
                      .toList()
                    ..sort((a, b) => a.matchDate.compareTo(b.matchDate));

                  final nextThree = upcomingMatches.take(3).toList();
                  final userTips = tipState.tips[userId] ?? [];

                  return TipList(
                    userId: userId,
                    tips: userTips,
                    matches: nextThree,
                    teams: teamState.teams,
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
