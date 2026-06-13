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

  static const double _estimatedMobileItemHeight = 58.0;
  static const double _estimatedDesktopItemHeight = 72.0;

  @override
  void initState() {
    super.initState();
    _scheduleScrollToCurrentUser();
  }

  @override
  void didUpdateWidget(covariant CommunityTipList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rankingMode != widget.rankingMode ||
        oldWidget.users != widget.users ||
        oldWidget.allTips != widget.allTips ||
        oldWidget.match.id != widget.match.id) {
      _scheduleScrollToCurrentUser();
    }
  }

  void _scheduleScrollToCurrentUser() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        _scrollToCurrentUser();
      });

      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        _ensureCurrentUserVisible();
      });

      Future.delayed(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        _ensureCurrentUserVisible();
      });
    });
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

    final isMobile = MediaQuery.of(context).size.width < 600;
    final estimatedItemHeight =
        isMobile ? _estimatedMobileItemHeight : _estimatedDesktopItemHeight;

    final viewportHeight = _scrollController.position.viewportDimension;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    final estimatedOffset = (idx * estimatedItemHeight) -
        (viewportHeight / 2) +
        (estimatedItemHeight / 2);

    final clampedOffset = estimatedOffset.clamp(
      0.0,
      maxScrollExtent,
    );

    _scrollController.jumpTo(clampedOffset);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureCurrentUserVisible();
    });
  }

  void _ensureCurrentUserVisible() {
    final currentContext = _currentUserKey.currentContext;
    if (currentContext == null) return;

    Scrollable.ensureVisible(
      currentContext,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.5,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildChampionFlag({
    required Team? championTeam,
    required double size,
  }) {
    return Tooltip(
      message: championTeam != null ? championTeam.name : 'None',
      child: SizedBox(
        width: size,
        height: size,
        child: championTeam != null
            ? ClipOval(
                child: Flag.fromString(
                  championTeam.flagCode,
                  height: size,
                  width: size,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: Icon(
                  Icons.help_outline,
                  size: size * 0.65,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final sortedUsers = _sortedUsers();
    final ranks = _ranks(sortedUsers);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomPadding = MediaQuery.of(context).padding.bottom +
            (constraints.maxHeight * 0.65).clamp(180.0, 420.0);

        return ListView.separated(
          controller: _scrollController,
          padding: EdgeInsets.only(
            bottom: bottomPadding,
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
                child: isMobile
                    ? _CommunityMobileRow(
                        rank: displayRank,
                        user: user,
                        championFlag: _buildChampionFlag(
                          championTeam: championTeam,
                          size: 18,
                        ),
                        jokerSum: user.jokerSum,
                        sixer: user.sixer,
                        tippedCount: tippedCount,
                        matchPoints: matchPoints,
                        tip: tip,
                      )
                    : _CommunityDesktopRow(
                        rank: displayRank,
                        user: user,
                        championFlag: _buildChampionFlag(
                          championTeam: championTeam,
                          size: 18,
                        ),
                        jokerSum: user.jokerSum,
                        sixer: user.sixer,
                        tippedCount: tippedCount,
                        totalPoints: totalPoints,
                        matchPoints: matchPoints,
                        tip: tip,
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CommunityMobileRow extends StatelessWidget {
  final int rank;
  final AppUser user;
  final Widget championFlag;
  final int jokerSum;
  final int sixer;
  final int tippedCount;
  final int matchPoints;
  final Tip? tip;

  const _CommunityMobileRow({
    required this.rank,
    required this.user,
    required this.championFlag,
    required this.jokerSum,
    required this.sixer,
    required this.tippedCount,
    required this.matchPoints,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = theme.textTheme.bodySmall?.color ?? Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(
                '#$rank',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                user.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            RichText(
              textAlign: TextAlign.end,
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(text: '$matchPoints'),
                  TextSpan(
                    text: ' pkt',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            championFlag,
            const SizedBox(width: 8),
            _CompactStatIcon(
              icon: Icons.star,
              color: Colors.amber,
              value: '$jokerSum',
              tooltip: 'Joker',
            ),
            const SizedBox(width: 9),
            _CompactStatIcon(
              icon: Icons.adjust,
              color: foregroundColor,
              value: '$sixer',
              tooltip: '6er',
            ),
            const SizedBox(width: 9),
            _CompactStatIcon(
              icon: Icons.edit_note,
              color: foregroundColor,
              value: '$tippedCount',
              tooltip: 'Tipps',
            ),
            const Spacer(),
            Text(
              tip?.tipHome != null && tip?.tipGuest != null
                  ? 'Tipp ${tip?.tipHome}:${tip?.tipGuest}'
                  : 'Tipp –',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                color: tip?.tipHome != null && tip?.tipGuest != null
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommunityDesktopRow extends StatelessWidget {
  final int rank;
  final AppUser user;
  final Widget championFlag;
  final int jokerSum;
  final int sixer;
  final int tippedCount;
  final int totalPoints;
  final int matchPoints;
  final Tip? tip;

  const _CommunityDesktopRow({
    required this.rank,
    required this.user,
    required this.championFlag,
    required this.jokerSum,
    required this.sixer,
    required this.tippedCount,
    required this.totalPoints,
    required this.matchPoints,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = theme.textTheme.bodySmall?.color ?? Colors.white;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            '#$rank',
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
                  championFlag,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 9,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CompactStatIcon(
                          icon: Icons.star,
                          color: Colors.amber,
                          value: '$jokerSum',
                          tooltip: 'Joker',
                        ),
                        _CompactStatIcon(
                          icon: Icons.adjust,
                          color: foregroundColor,
                          value: '$sixer',
                          tooltip: '6er',
                        ),
                        _CompactStatIcon(
                          icon: Icons.edit_note,
                          color: foregroundColor,
                          value: '$tippedCount',
                          tooltip: 'Tipps',
                        ),
                        _CompactStatIcon(
                          icon: Icons.emoji_events,
                          color: foregroundColor,
                          value: '$totalPoints',
                          tooltip: 'Gesamtpunkte',
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
                  TextSpan(text: '$matchPoints'),
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
    );
  }
}

class _CompactStatIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String tooltip;

  const _CompactStatIcon({
    required this.icon,
    required this.color,
    required this.value,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color.withOpacity(0.9),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
