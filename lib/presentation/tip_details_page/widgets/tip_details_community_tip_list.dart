import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';

class CommunityTipList extends StatefulWidget {
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
  State<CommunityTipList> createState() => _CommunityTipListState();
}

class _CommunityTipListState extends State<CommunityTipList> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 70.0; // Approximate height per item

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentUser();
    });
  }

  void _scrollToCurrentUser() {
    final sortedUsers = List<AppUser>.from(widget.users)
      ..sort((a, b) {
        final scoreComparison = b.score.compareTo(a.score);
        if (scoreComparison != 0) return scoreComparison;

        final jokerComparison = a.jokerSum.compareTo(b.jokerSum);
        if (jokerComparison != 0) return jokerComparison;

        final sixersComparison = b.sixer.compareTo(a.sixer);
        if (sixersComparison != 0) return sixersComparison;

        return a.name.compareTo(b.name);
      });

    final currentUserIndex =
        sortedUsers.indexWhere((u) => u.id == widget.currentUserId);

    if (currentUserIndex >= 0 && _scrollController.hasClients) {
      // Zentriere User mit 2-3 Usern darüber
      final targetOffset = (currentUserIndex - 2) * _itemHeight;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final finalOffset = targetOffset.clamp(0.0, maxScroll);
      _scrollController.jumpTo(finalOffset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ FIX: Sortiere User nach gleicher Logik wie Rangliste
    final sortedUsers = List<AppUser>.from(widget.users)
      ..sort((a, b) {
        final scoreComparison = b.score.compareTo(a.score);
        if (scoreComparison != 0) return scoreComparison;

        final jokerComparison = a.jokerSum.compareTo(b.jokerSum);
        if (jokerComparison != 0) return jokerComparison;

        final sixersComparison = b.sixer.compareTo(a.sixer);
        if (sixersComparison != 0) return sixersComparison;

        return a.name.compareTo(b.name);
      });

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 100,
      ),
      itemCount: sortedUsers.length,
      separatorBuilder: (_, __) => Divider(
        color: theme.dividerColor.withOpacity(0.05),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final user = sortedUsers[index];
        // ✅ FIX: Rang basiert auf sortierter Position (1-basiert)
        final displayRank = index + 1;
        final tip = widget.allTips[user.id]?.firstWhere(
          (t) => t.matchId == widget.match.id,
          orElse: () => Tip.empty(user.id),
        );
        final isCurrentUser = user.id == widget.currentUserId;
        final championTeam = widget.teams
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
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child:
                      Text('#$displayRank', style: theme.textTheme.bodyMedium),
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
                              width: 18,
                              height: 18,
                              child: championTeam != null
                                  ? ClipOval(
                                      child: Flag.fromString(
                                        championTeam.flagCode,
                                        height: 18,
                                        width: 18,
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
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 10,
                                  child: Text('${user.jokerSum}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 1),
                                const Icon(Icons.star,
                                    size: 10, color: Colors.amber),
                                const SizedBox(width: 2),
                                SizedBox(
                                  width: 30,
                                  child: Text('${user.sixer} 6er',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 2),
                                SizedBox(
                                  width: 18,
                                  child: Text('${user.score}p',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
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
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: tip?.joker == true
                              ? const Icon(Icons.star,
                                  color: Colors.amber, size: 16)
                              : null,
                        ),
                        Text(
                          (tip?.tipHome != null && tip?.tipGuest != null)
                              ? '${tip?.tipHome} : ${tip?.tipGuest}'
                              : '–',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: (tip?.tipHome != null &&
                                    tip?.tipGuest != null)
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.4),
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
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(text: '${tip?.points ?? 0}'),
                          TextSpan(
                            text: ' pkt',
                            style: theme.textTheme.bodySmall,
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
    );
  }
}
