import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/home_page/widget/ranking_user_list.dart';
import 'package:flutter_web/application/ranking/ranking_bloc.dart';


class RankingSection extends StatelessWidget {
  final List<Team> teams;

  const RankingSection({
    required this.teams,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return BlocBuilder<RankingBloc, RankingState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // final sortedUsers = [...state.users]
        //   ..sort((a, b) => a.rank.compareTo(b.rank));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                const SizedBox(width: 12),
                Text('Ranking', style: themeData.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: RankingUserList(
                users: state.users.take(2).toList(),
                teams: teams,
                currentUser: state.currentUser,
              ),
              secondChild: RankingUserList(
                users: state.users,
                teams: teams,
                currentUser: state.currentUser,
              ),
              crossFadeState: state.expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
            if (state.users.length > 2)
              Center(
                child: IconButton(
                  icon: Icon(
                    state.expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: themeData.primaryIconTheme.color,
                  ),
                  onPressed: () {
                    context.read<RankingBloc>().add(ToggleExpandedEvent());
                  },
                  tooltip: state.expanded
                      ? 'Weniger anzeigen'
                      : 'Mehr anzeigen',
                ),
              ),
          ],
        );
      },
    );
  }
}
