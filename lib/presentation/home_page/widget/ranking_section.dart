import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/ranking/ranking_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/presentation/home_page/widget/ranking_user_list.dart';

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
    return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
      builder: (context, teamState) {
        if (teamState is TeamsControllerLoaded) {
          final themeData = Theme.of(context);
          final teams = teamState.teams;
          users.sort((a, b) => a.rank.compareTo(b.rank));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rangliste",
                    style: themeData.textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BlocBuilder<RankingBloc, RankingState>(
                builder: (context, rankingState) {
                  final currentUserIndex =
                      users.indexWhere((u) => u.id == userId);
                  List<AppUser> visibleUsers;

                  if (rankingState.expanded || users.length <= 5) {
                    visibleUsers = users;
                  } else {
                    if (currentUserIndex != -1) {
                      int start = (currentUserIndex - 2).clamp(0, users.length);
                      int end = (currentUserIndex + 3).clamp(0, users.length);

                      if (start == 0) {
                        end = (start + 5).clamp(0, users.length);
                      }
                      if (end == users.length) {
                        start = (end - 5).clamp(0, users.length);
                      }
                      visibleUsers = users.sublist(start, end);
                    } else {
                      visibleUsers = users.take(5).toList();
                    }
                  }

                  return AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        RankingUserList(
                          users: visibleUsers,
                          teams: teams,
                          currentUser: userId,
                        ),
                        if (users.length > 5)
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
                    ),
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
    );
  }
}
