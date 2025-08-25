import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';

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

    return ListView.builder(
      itemCount: sortedUsers.length,
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final user = sortedUsers[index];
        final isCurrentUser = currentUser == user.name;

        final champion = teams.firstWhere(
          (team) => team.id == user.championId,
          orElse: () => Team.empty(),
        );

        final tip = tips[user.name]?.firstWhere(
          (t) => t.matchId == match.id,
          orElse: () => Tip.empty(user.name),
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
                SizedBox(
                  width: 40,
                  child: Text('#${user.rank}', style: textTheme.bodyMedium),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    user.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (tip != null)
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 32),
                        Text(
                          "${tip.tipGuest}",
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          ":",
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "${tip.tipGuest}",
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(width: 32),
                        Column(children: [
                          if (tip.joker) ...[
                            const Icon(Icons.star,
                                size: 18, color: Colors.amber),
                          ],
                        ])
                      ],
                    ),
                  ),
                // to align with tip input
                const SizedBox(width: 20,),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Tooltip(
                              message: champion.name,
                              child: ClipOval(
                                child: Flag.fromString(
                                  champion.flagCode,
                                  height: 20,
                                  width: 20,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 24,
                            ),
                            SizedBox(
                              width: 60,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${user.jokerSum}',
                                      style: textTheme.displayLarge?.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      )),
                                  const SizedBox(width: 4),
                                  const Tooltip(
                                    message: 'Joker',
                                    child: Icon(Icons.star,
                                        size: 18, color: Colors.amber),
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
                                  style: textTheme.displaySmall?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(text: '${user.sixer}'),
                                    TextSpan(
                                      text: ' 6er',
                                      style: textTheme.bodySmall?.copyWith(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold),
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
                                  style: textTheme.displaySmall?.copyWith(
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
