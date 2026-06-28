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

  static const double _estimatedMobileItemHeight = 70.0;
  static const double _estimatedDesktopItemHeight = 72.0;

  /// Verhindert erneutes Auto-Scroll bei Datenänderungen
  bool _hasScrolledForCurrentMatch = false;

  @override
  void initState() {
    super.initState();
    _scheduleScrollToCurrentUser();
  }

  @override
  void didUpdateWidget(covariant CommunityTipList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Nur bei Match-Wechsel oder Moduswechsel: Reset und neu scrollen
    final matchChanged = oldWidget.match.id != widget.match.id;
    final modeChanged = oldWidget.rankingMode != widget.rankingMode;

    if (matchChanged || modeChanged) {
      _hasScrolledForCurrentMatch = false;
      _scheduleScrollToCurrentUser();
    }
    // Debouncing erfolgt zentral im AuthControllerBloc
  }

  void _scheduleScrollToCurrentUser() {
    if (_hasScrolledForCurrentMatch) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasScrolledForCurrentMatch) return;

      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted || _hasScrolledForCurrentMatch) return;
        _scrollToCurrentUser();
        _hasScrolledForCurrentMatch = true;
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

  int _compareByTotalRanking(AppUser a, AppUser b) {
    final scoreComparison = b.score.compareTo(a.score);
    if (scoreComparison != 0) return scoreComparison;

    final sixersComparison = b.sixer.compareTo(a.sixer);
    if (sixersComparison != 0) return sixersComparison;

    final jokerComparison = a.jokerSum.compareTo(b.jokerSum);
    if (jokerComparison != 0) return jokerComparison;

    return a.name.compareTo(b.name);
  }

  bool _isTotalTie(AppUser a, AppUser b) {
    return a.score == b.score && a.sixer == b.sixer && a.jokerSum == b.jokerSum;
  }

  bool _isMatchTie(AppUser a, AppUser b) {
    return _matchPointsForUser(a) == _matchPointsForUser(b) &&
        a.score == b.score &&
        a.sixer == b.sixer &&
        a.jokerSum == b.jokerSum;
  }

  List<AppUser> _sortedUsers() {
    final sortedUsers = List<AppUser>.from(widget.users);

    if (widget.rankingMode == CommunityRankingMode.match) {
      sortedUsers.sort((a, b) {
        final pointsComparison =
            _matchPointsForUser(b).compareTo(_matchPointsForUser(a));

        if (pointsComparison != 0) return pointsComparison;

        // Wichtig:
        // Bei gleicher Match-Punktzahl wird NICHT nach getippten Spielen sortiert,
        // sondern nach denselben Tie-Breakern wie beim Gesamt-Ranking.
        return _compareByTotalRanking(a, b);
      });

      return sortedUsers;
    }

    sortedUsers.sort(_compareByTotalRanking);
    return sortedUsers;
  }

  List<int> _ranks(List<AppUser> sortedUsers) {
    final ranks = <int>[];

    for (var i = 0; i < sortedUsers.length; i++) {
      if (i == 0) {
        ranks.add(1);
        continue;
      }

      final prev = sortedUsers[i - 1];
      final curr = sortedUsers[i];

      final isTie = widget.rankingMode == CommunityRankingMode.match
          ? _isMatchTie(curr, prev)
          : _isTotalTie(curr, prev);

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

    // Direkt Liste anzeigen - Debouncing erfolgt im BLoC
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
                        totalPoints: totalPoints,
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
  final int totalPoints;
  final int matchPoints;
  final Tip? tip;

  const _CommunityMobileRow({
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

    final hasTip = tip?.tipHome != null && tip?.tipGuest != null;
    final tipText = hasTip ? '${tip?.tipHome}:${tip?.tipGuest}' : '–';

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
        SizedBox(
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    championFlag,
                    const SizedBox(width: 8),
                    _CompactStatIcon(
                      icon: Icons.star,
                      color: Colors.amber,
                      value: '$jokerSum',
                      tooltip: 'Joker',
                    ),
                    const SizedBox(width: 8),
                    _CompactStatIcon(
                      icon: Icons.adjust,
                      color: foregroundColor,
                      value: '$sixer',
                      tooltip: '6er',
                    ),
                    const SizedBox(width: 8),
                    _CompactStatIcon(
                      icon: Icons.edit_note,
                      color: foregroundColor,
                      value: '$tippedCount',
                      tooltip: 'Tipps',
                    ),
                    const SizedBox(width: 8),
                    _CompactStatIcon(
                      icon: Icons.emoji_events,
                      color: foregroundColor,
                      value: '$totalPoints',
                      tooltip: 'Gesamtpunkte',
                    ),
                  ],
                ),
              ),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: tip?.joker == true
                        ? Border.all(
                            color: Colors.amber.withOpacity(0.8),
                            width: 2,
                          )
                        : null,
                  ),
                  child: Text(
                    tipText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: hasTip
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                    overflow: TextOverflow.visible,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: tip?.joker == true
                    ? Border.all(
                        color: Colors.amber.withOpacity(0.8),
                        width: 2,
                      )
                    : null,
              ),
              child: Text(
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
