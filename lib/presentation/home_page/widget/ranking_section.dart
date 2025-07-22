import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/ranking/ranking_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/presentation/home_page/widget/ranking_user_list.dart';
import 'package:flutter_web/injections.dart';

class RankingSection extends StatelessWidget {
  const RankingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RankingBloc>(
          create: (_) => sl<RankingBloc>()..add(LoadRankingEvent()),
        ),
        BlocProvider<TeamsControllerBloc>(
          create: (_) =>
              sl<TeamsControllerBloc>()..add(TeamsControllerAllEvent()),
        ),
      ],
      child: BlocBuilder<RankingBloc, RankingState>(
        builder: (context, rankingState) {
          return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
            builder: (context, teamState) {
              if (teamState is TeamsControllerLoaded &&
                  rankingState is RankingLoaded) {
                final themeData = Theme.of(context);
                final teams = (teamState).teams;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 30),
                        const SizedBox(width: 12),
                        Text('Ranking',
                            style: themeData.textTheme.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      firstChild: RankingUserList(
                        users: rankingState.sortedUsers.take(2).toList(),
                        teams: teams,
                        currentUser: rankingState.currentUser,
                      ),
                      secondChild: RankingUserList(
                        users: rankingState.sortedUsers,
                        teams: teams,
                        currentUser: rankingState.currentUser,
                      ),
                      crossFadeState: rankingState.expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                    ),
                    if (rankingState.sortedUsers.length > 2)
                      Center(
                        child: IconButton(
                          icon: Icon(
                            rankingState.expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: themeData.primaryIconTheme.color,
                          ),
                          onPressed: () {
                            context
                                .read<RankingBloc>()
                                .add(ToggleRankingViewEvent());
                          },
                          tooltip:
                              rankingState.expanded ? 'Weniger anzeigen' : 'Mehr anzeigen',
                        ),
                      ),
                  ],
                );
              } else if (teamState is TeamsControllerLoading ||
                  rankingState is RankingLoading) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return const Center(child: Text("Failure"));
              }
            },
          );
        },
      ),
    );
  }
}
