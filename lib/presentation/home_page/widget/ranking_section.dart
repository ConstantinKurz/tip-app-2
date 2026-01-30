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

          // Sortiere nach Score (absteigend), bei Gleichstand nach Namen
          final sortedUsers = List<AppUser>.from(users)
            ..sort((a, b) {
              final scoreComparison = b.score.compareTo(a.score);
              if (scoreComparison != 0) return scoreComparison;
              
              final jokerComparison = a.jokerSum.compareTo(b.jokerSum);
              if (jokerComparison != 0) return jokerComparison;
              
              final sixersComparison = b.sixer.compareTo(a.sixer);
              if (sixersComparison != 0) return sixersComparison;
              
              return a.name.compareTo(b.name);
            });

          // Debug: Zeige die sortierten User
          print('📊 Sortierte Rangliste:');
          for (int i = 0; i < sortedUsers.length; i++) {
            final user = sortedUsers[i];
            final isCurrentUser = user.id == userId;
            print('  ${i + 1}. ${user.name} (${user.score} Pkt) ${isCurrentUser ? "← DU" : ""}');
          }

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
                      sortedUsers.indexWhere((u) => u.id == userId);
                  
                  print('🔍 Aktueller User Index: $currentUserIndex');
                  
                  List<AppUser> visibleUsers;

                  if (rankingState.expanded || sortedUsers.length <= 5) {
                    // Zeige alle User
                    visibleUsers = sortedUsers;
                    print('✅ Expanded: Zeige alle ${visibleUsers.length} User');
                  } else {
                    // Collapsed: Zeige 1 über dir, dich, 2 unter dir
                    if (currentUserIndex == -1) {
                      // User nicht gefunden: Zeige Top 5
                      visibleUsers = sortedUsers.take(5).toList();
                      print('⚠️ User nicht gefunden: Zeige Top 5');
                    } else if (currentUserIndex <= 1) {
                      // User ist schon in Top 2: Zeige Top 5
                      visibleUsers = sortedUsers.take(5).toList();
                      print('✅ Collapsed (Top Player): Zeige Top 5');
                    } else {
                      // Zeige: 2 über dir, dich, 2 unter dir = 5 User total
                      int start = currentUserIndex - 2;
                      int end = currentUserIndex + 3;
                      
                      visibleUsers = sortedUsers.sublist(start, end);
                      
                      print('✅ Collapsed (Um dich herum): Zeige ${visibleUsers.length} User');
                      for (int i = 0; i < visibleUsers.length; i++) {
                        print('    ${start + i + 1}. ${visibleUsers[i].name}');
                      }
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
