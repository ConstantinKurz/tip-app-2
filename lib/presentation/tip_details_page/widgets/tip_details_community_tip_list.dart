import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';

enum CommunityRankingMode {
  total,
  match,
}

class CommunityTipList extends StatefulWidget {
  final List<AppUser> users;
  final Map<String, List<Tip>> allTips;
  final CustomMatch match;
  final String currentUserId;
  final List<Team> teams;
  final List<CustomMatch> matches;
  final CommunityRankingMode rankingMode;

  const CommunityTipList({
    Key? key,
    required this.users,
    required this.allTips,
    required this.match,
    required this.currentUserId,
    required this.teams,
    required this.matches,
    required this.rankingMode,
  }) : super(key: key);

  @override
  State<CommunityTipList> createState() => _CommunityTipListState();
}

class _CommunityTipListState extends State<CommunityTipList> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentUserKey = GlobalKey();

  static const double _estimatedItemHeight = 78.0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _scrollToCurrentUser();
      });
    });
  }

  @override
  void didUpdateWidget(covariant CommunityTipList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rankingMode != widget.rankingMode ||
        oldWidget.users != widget.users ||
        oldWidget.allTips != widget.allTips ||
        oldWidget.match.id != widget.match.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (!mounted) return;
          _scrollToCurrentUser();
        });
      });
    }
  }

  Tip? _tipForUserAndCurrentMatch(AppUser user) {
    return widget.allTips[user.id]?.firstWhere(
      (t) => t.matchId == widget.match.id,
      orElse: () => Tip.empty(user.id),
    );
  }

  int _matchPointsForUser(AppUser user) {
    return _tipForUserAndCurrentMatch(user)?.points ?? 0;
  }

  List<AppUser> _sortedUsers() {
    final sortedUsers = List<AppUser>.from(widget.users);

    if (widget.rankingMode == CommunityRankingMode.match) {
      sortedUsers.sort((a, b) {
        final pointsComparison =
            _matchPointsForUser(b).compareTo(_matchPointsForUser(a));

        if (pointsComparison != 0) return pointsComparison;

        return a.name.compareTo(b.name);
      });

      return sortedUsers;
    }

    sortedUsers.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;

      final sixersComparison = b.sixer.compareTo(a.sixer);
      if (sixersComparison != 0) return sixersComparison;

      final jokerComparison = a.jokerSum.compareTo(b.jokerSum);
      if (jokerComparison != 0) return jokerComparison;

      return a.name.compareTo(b.name);
    });

    return sortedUsers;
  }

  List<int> _ranks(List<AppUser> sortedUsers) {
    final ranks = <int>[];

    for (var i = 0; i < sortedUsers.length; i++) {
      if (widget.rankingMode == CommunityRankingMode.match) {
        ranks.add(i + 1);
        continue;
      }

      if (i == 0) {
        ranks.add(1);
        continue;
      }

      final prev = sortedUsers[i - 1];
      final curr = sortedUsers[i];

      final isTie = curr.score == prev.score &&
          curr.sixer == prev.sixer &&
          curr.jokerSum == prev.jokerSum;

      if (isTie) {
        ranks.add(ranks[i - 1]);
      } else {
        ranks.add(i + 1);
      }
    }

    return ranks;
  }

  void _scrollToCurrentUser() {
    if (!_scrollController.hasClients) return;

    final sortedUsers = _sortedUsers();
    final idx = sortedUsers.indexWhere((u) => u.id == widget.currentUserId);

    if (idx < 0) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    final estimatedOffset = (idx * _estimatedItemHeight) -
        (viewportHeight / 2) +
        (_estimatedItemHeight / 2);

    final clampedOffset = estimatedOffset.clamp(
      0.0,
      maxScrollExtent,
    );

    _scrollController.jumpTo(clampedOffset);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final currentContext = _currentUserKey.currentContext;
      if (currentContext == null) return;

      Scrollable.ensureVisible(
        currentContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final sortedUsers = _sortedUsers();
    final ranks = _ranks(sortedUsers);

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
        final userTips = widget.allTips[user.id] ?? [];

        final tippedCount = userTips.where((t) {
          final matchForTip = widget.matches.firstWhere(
            (m) => m.id == t.matchId,
            orElse: () => CustomMatch.empty(),
          );

          return t.tipHome != null &&
              t.tipGuest != null &&
              matchForTip.homeScore != null &&
              matchForTip.guestScore != null;
        }).length;

        final displayRank = ranks.isNotEmpty ? ranks[index] : index + 1;
        final tip = _tipForUserAndCurrentMatch(user);

        final matchPoints = tip?.points ?? 0;
        final totalPoints = user.score;

        final isCurrentUser = user.id == widget.currentUserId;
        final championTeam =
            widget.teams.where((e) => e.id == user.championId).firstOrNull;

        return Container(
          key: isCurrentUser ? _currentUserKey : ValueKey(user.id),
          decoration: isCurrentUser
              ? BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 8.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '#$displayRank',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
                          const SizedBox(width: 4),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      child: Text(
                                        '${user.jokerSum}',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.star,
                                      size: 10,
                                      color: Colors.amber,
                                    ),
                                  ],
                                ),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 80),
                                  child: Text(
                                    '${user.sixer} 6er',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 56,
                                  child: Text(
                                    '$tippedCount ${tippedCount == 1 ? 'Tipp' : 'Tipps'}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 58,
                                  child: Text(
                                    '$matchPoints pkt',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.85),
                                    ),
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                              ? const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                )
                              : null,
                        ),
                        Text(
                          tip?.tipHome != null && tip?.tipGuest != null
                              ? '${tip?.tipHome} : ${tip?.tipGuest}'
                              : '–',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: tip?.tipHome != null && tip?.tipGuest != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(width: 48),
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
                          TextSpan(text: '$totalPoints'),
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
