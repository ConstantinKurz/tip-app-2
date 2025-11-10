import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/ranking/ranking_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/injections.dart';
// TODO: nicht gleiche breite wie homepage. Homepage button hinzufügen
class TipDetailsRankingUserList extends StatelessWidget {
  final List<AppUser> users;
  final List<Team> teams;
  final String currentUser;
  final Map<String, List<Tip>> tips;
  final CustomMatch match;

  const TipDetailsRankingUserList({
    Key? key,
    required this.users,
    required this.teams,
    required this.currentUser,
    required this.tips,
    required this.match,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sortedUsers = [...users]..sort((a, b) => a.rank.compareTo(b.rank));

    return BlocProvider<RankingBloc>(
      create: (_) => sl<RankingBloc>(),
      child: BlocBuilder<RankingBloc, RankingState>(
        builder: (context, rankingState) {
          final currentUserIndex =
              sortedUsers.indexWhere((u) => u.id == currentUser);
          List<AppUser> visibleUsers;

          if (rankingState.expanded || sortedUsers.length <= 5) {
            visibleUsers = sortedUsers;
          } else {
            if (currentUserIndex != -1) {
              int start = (currentUserIndex - 2).clamp(0, sortedUsers.length);
              int end = (currentUserIndex + 3).clamp(0, sortedUsers.length);

              if (start == 0) {
                end = (start + 5).clamp(0, sortedUsers.length);
              }
              if (end == sortedUsers.length) {
                start = (end - 5).clamp(0, sortedUsers.length);
              }
              visibleUsers = sortedUsers.sublist(start, end);
            } else {
              visibleUsers = sortedUsers.take(5).toList();
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: ListView.builder(
                  itemCount: visibleUsers.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final user = visibleUsers[index];
                    final isCurrentUser = currentUser == user.id;

                    final champion = teams.firstWhere(
                      (team) => team.id == user.championId,
                      orElse: () => Team.empty(),
                    );

                    final tip = tips[user.id]?.firstWhere(
                      (t) => t.matchId == match.id,
                      orElse: () => Tip.empty(user.id),
                    );

                    return Container(
                      decoration: isCurrentUser
                          ? BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Flexible(
                              // Gruppiert Rang und Name
                              flex: 1,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text('#${user.rank}',
                                        style: textTheme.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(
                                      user.name,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (tip != null)
                              Expanded(
                                // Nimmt den mittleren Platz ein
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${tip.tipHome ?? '-'}",
                                      style: textTheme.bodyMedium,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      ":",
                                      style: textTheme.bodyMedium,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      "${tip.tipGuest ?? '-'}",
                                      style: textTheme.bodyMedium,
                                    ),
                                    const SizedBox(width: 16),
                                    if (tip.joker)
                                      const Icon(Icons.star,
                                          size: 18, color: Colors.amber)
                                    else
                                      const SizedBox(width: 18),
                                  ],
                                ),
                              ),
                            SizedBox(
                              width: 180,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Tooltip(
                                        message: champion.id != "TBD"
                                            ? champion.name
                                            : 'None',
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: champion.id != "TBD"
                                              ? ClipOval(
                                                  child: Flag.fromString(
                                                    champion.flagCode,
                                                    height: 28,
                                                    width: 28,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : const ClipOval(
                                                  child: Icon(Icons.close,
                                                      size: 20,
                                                      color: Colors.grey),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 24,
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text('${user.jokerSum}',
                                                style: textTheme.displayLarge
                                                    ?.copyWith(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                )),
                                            const SizedBox(width: 4),
                                            const Tooltip(
                                              message: 'Joker',
                                              child: Icon(Icons.star,
                                                  size: 18,
                                                  color: Colors.amber),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: RichText(
                                          textAlign: TextAlign.end,
                                          text: TextSpan(
                                            style: textTheme.displaySmall
                                                ?.copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            children: [
                                              TextSpan(text: '${user.sixer}'),
                                              TextSpan(
                                                text: ' 6er',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 60,
                                        child: RichText(
                                          textAlign: TextAlign.end,
                                          text: TextSpan(
                                            style: textTheme.displaySmall
                                                ?.copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            children: [
                                              TextSpan(text: '${user.score}'),
                                              TextSpan(
                                                text: ' pkt',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (sortedUsers.length > 5)
                IconButton(
                  icon: Icon(
                    rankingState.expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () {
                    context.read<RankingBloc>().add(ToggleRankingViewEvent());
                  },
                  tooltip: rankingState.expanded
                      ? 'Weniger anzeigen'
                      : 'Mehr anzeigen',
                ),
            ],
          );
        },
      ),
    );
  }
}
