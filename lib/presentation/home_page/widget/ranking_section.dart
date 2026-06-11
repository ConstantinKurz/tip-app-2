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
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 800;

          // Sortiere nach Score (absteigend), bei Gleichstand nach Joker (absteigend), dann 6er (absteigend), dann Name
          final sortedUsers = List<AppUser>.from(users)
            ..sort((a, b) {
              final scoreComparison = b.score.compareTo(a.score);
              if (scoreComparison != 0) return scoreComparison;

              final jokerComparison = b.jokerSum.compareTo(a.jokerSum);
              if (jokerComparison != 0) return jokerComparison;

              final sixersComparison = b.sixer.compareTo(a.sixer);
              if (sixersComparison != 0) return sixersComparison;

              return a.name.compareTo(b.name);
            });

          // Berechne globale Ränge (olympisches Ranking): gleiche Score/Joker/Sixer erhalten gleichen Rang, nächster Rang = Position+1
          final List<int> globalRanks = [];
          for (var i = 0; i < sortedUsers.length; i++) {
            if (i == 0) {
              globalRanks.add(1);
              continue;
            }
            final prev = sortedUsers[i - 1];
            final curr = sortedUsers[i];
            final isTie = curr.score == prev.score &&
                curr.jokerSum == prev.jokerSum &&
                curr.sixer == prev.sixer;
            if (isTie) {
              // gleiche Position wie Vorgänger
              globalRanks.add(globalRanks[i - 1]);
            } else {
              // nächster Rang: Listenposition + 1 (Ränge werden übersprungen)
              globalRanks.add(i + 1);
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Rangliste",
                    style: isMobile
                        ? themeData.textTheme.headlineSmall!
                            .copyWith(fontSize: 14)
                        : themeData.textTheme.headlineSmall!,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BlocBuilder<RankingBloc, RankingState>(
                builder: (context, rankingState) {
                  final currentUserIndex =
                      sortedUsers.indexWhere((u) => u.id == userId);

                  List<AppUser> visibleUsers;

                  if (rankingState.expanded || sortedUsers.length <= 5) {
                    // Zeige alle User
                    visibleUsers = sortedUsers;
                  } else {
                    // Collapsed: Zeige 1 über dir, dich, 2 unter dir
                    if (currentUserIndex == -1) {
                      // User nicht gefunden: Zeige Top 5
                      visibleUsers = sortedUsers.take(5).toList();
                    } else if (currentUserIndex <= 1) {
                      // User ist schon in Top 2: Zeige Top 5
                      visibleUsers = sortedUsers.take(5).toList();
                    } else {
                      // Zeige: 2 über dir, dich, 2 unter dir = 5 User total
                      int start = currentUserIndex - 2;
                      int end = currentUserIndex + 3;

                      // Begrenze end auf die Listengröße
                      if (end > sortedUsers.length) {
                        end = sortedUsers.length;
                        // Wenn am Ende, zeige mehr User von oben
                        start = (sortedUsers.length - 5)
                            .clamp(0, sortedUsers.length);
                      }

                      visibleUsers = sortedUsers.sublist(start, end);
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
                          currentUserId: userId,
                          scrollToCurrentUser: rankingState.expanded,
                          globalUserIndices: visibleUsers
                              .map((user) => globalRanks[sortedUsers.indexOf(user)])
                              .toList(),
                        ),
                        if (sortedUsers.length > 5)
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

        return const SizedBox.shrink();
      },
    );
  }
}
