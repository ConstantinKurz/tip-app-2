import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CommunityTipList extends StatelessWidget {
  final List<AppUser> users;
  final Map<String, List<Tip>> allTips;
  final CustomMatch match;
  final String currentUserId;
  final List<Team> teams;

  const CommunityTipList({
    Key? key,
    required this.users,
    required this.allTips,
    required this.match,
    required this.currentUserId,
    required this.teams,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentUserIndex = users.indexWhere((u) => u.id == currentUserId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ScrollablePositionedList.separated(
            initialScrollIndex: currentUserIndex >= 0 ? currentUserIndex : 0,
            itemCount: users.length,
            separatorBuilder: (_, __) => Divider(
              color: theme.dividerColor.withOpacity(0.05),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final user = users[index];
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
                      SizedBox(
                        width: 36,
                        child: Text('#${user.rank}',
                            style: theme.textTheme.bodyMedium),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Tooltip(
                                  message: championTeam != null
                                      ? championTeam.name
                                      : 'None',
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: championTeam != null
                                        ? ClipOval(
                                            child: Flag.fromString(
                                              championTeam.flagCode,
                                              height: 20,
                                              width: 20,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey[300],
                                            ),
                                            child: const Icon(
                                              Icons.help_outline,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 32,
                                  child: Row(
                                    children: [
                                      Text('${user.jokerSum}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          )),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.star,
                                          size: 14, color: Colors.amber),
                                    ],
                                  ),
                                ),
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
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: "Gesamtpunkte",
                                  child: SizedBox(
                                    width: 96,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${user.score}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            )),
                                        Text(' Pkt',
                                            style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (tip!.joker)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4.0),
                                  child: Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                ),
                              if (!tip.joker)
                                const SizedBox(
                                  width: 20,
                                ),
                              Text(
                                (tip.tipHome != null && tip.tipGuest != null)
                                    ? '${tip.tipHome} : ${tip.tipGuest}'
                                    : '–',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  color: (tip.tipHome != null &&
                                          tip.tipGuest != null)
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(
                                width: 48,
                              )
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          width: 60,
                          child: RichText(
                            textAlign: TextAlign.end,
                            text: TextSpan(
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(text: '${tip.points ?? 0}'),
                                TextSpan(
                                  text: ' pkt',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
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
