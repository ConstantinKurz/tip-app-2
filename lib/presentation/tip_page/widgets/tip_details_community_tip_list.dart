import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';

class CommunityTipList extends StatelessWidget {
  final List<AppUser> users;
  final Map<String, List<Tip>> allTips;
  final CustomMatch match;
  final String currentUserId;
  final List<Team> teams; // <-- neu als Parameter

  const CommunityTipList({
    Key? key,
    required this.users,
    required this.allTips,
    required this.match,
    required this.currentUserId,
    required this.teams, // <-- neu
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedUsers = users.toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
          child: Text(
            'Tipps der Community',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: sortedUsers.length,
            separatorBuilder: (_, __) => Divider(
              color: theme.dividerColor.withOpacity(0.05),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final user = sortedUsers[index];
              final tip = allTips[user.id]?.firstWhere(
                (t) => t.matchId == match.id,
                orElse: () => Tip.empty(user.id),
              );
              final isCurrentUser = user.id == currentUserId;
              final championTeam = teams
                  .where((element) => element.id == user.championId)
                  .firstOrNull;

              BoxDecoration? decoration;
              if (isCurrentUser) {
                decoration = BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                );
              }

              return Container(
                decoration: decoration,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rang
                      SizedBox(
                        width: 36,
                        child: Text('#${user.rank}',
                            style: theme.textTheme.bodyMedium),
                      ),
                      // Name, Tipp und Zusatzinfos in einer Spalte
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name und Tipp in einer Zeile
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (tip!.tipHome != null && tip.tipGuest != null)
                                      ? '${tip.tipHome} : ${tip.tipGuest}'
                                      : '–',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: (tip!.tipHome != null &&
                                            tip.tipGuest != null)
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.4),
                                  ),
                                ),
                                if (tip!.joker)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Champion, JokerSum, 6er in einer Zeile
                            Row(
                              children: [
                                // Champion
                                Tooltip(
                                  message:
                                      championTeam != null ? championTeam.name : 'None',
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: championTeam != null
                                        ? ClipOval(
                                            child: Flag.fromString(
                                              championTeam.flagCode,
                                              height: 28,
                                              width: 28,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const ClipOval(
                                            child: Icon(Icons.close,
                                                size: 20, color: Colors.grey),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // JokerSum
                                Row(
                                  children: [
                                    Text('${user.jokerSum}',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        )),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.star,
                                        size: 14, color: Colors.amber),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                // 6er
                                Row(
                                  children: [
                                    Text('${user.sixer}',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        )),
                                    Text(' 6er',
                                        style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Punkte aus dem Tipp (rechts)
                      SizedBox(
                        width: 60,
                        child: RichText(
                          textAlign: TextAlign.end,
                          text: TextSpan(
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(text: '${user.score}'),
                              TextSpan(
                                text: ' pkt',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontSize: 12),
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
          ),
        ),
      ],
    );
  }
}
