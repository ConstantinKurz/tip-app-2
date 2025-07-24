import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/ranking/ranking_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/presentation/home_page/widget/ranking_user_list.dart';
import 'package:flutter_web/injections.dart';

class RankingSection extends StatelessWidget {
  final String userId;
  final List<AppUser> users;

  const RankingSection({
    Key? key,
    required this.userId,
    required this.users,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RankingBloc>(
      create: (_) => sl<RankingBloc>(),
      child: BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
        builder: (context, teamState) {
          if (teamState is TeamsControllerLoaded) {
            final themeData = Theme.of(context);
            final teams = teamState.teams;
            users.sort((a, b) => a.rank.compareTo(b.rank));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 30),
                    const SizedBox(width: 12),
                    Text('Ranking', style: themeData.textTheme.headlineSmall),
                  ],
                ),
                const SizedBox(height: 12),
                BlocBuilder<RankingBloc, RankingState>(
                  builder: (context, rankingState) {
                    return Column(
                      children: [
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          firstChild: RankingUserList(
                            users: users.take(2).toList(),
                            teams: teams,
                            currentUser: userId,
                          ),
                          secondChild: RankingUserList(
                            users: users,
                            teams: teams,
                            currentUser: userId,
                          ),
                          crossFadeState: rankingState.expanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                        ),
                        if (users.length > 2)
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
                              tooltip: rankingState.expanded
                                  ? 'Weniger anzeigen'
                                  : 'Mehr anzeigen',
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          }

          if (teamState is TeamsControllerLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return const Center(child: Text("Fehler beim Laden"));
        },
      ),
    );
  }
}
