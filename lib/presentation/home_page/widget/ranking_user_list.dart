import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class RankingUserList extends StatelessWidget {
  final List<AppUser> users;
  final List<Team> teams;
  final String currentUserId;
  final bool scrollToCurrentUser;
  final List<int> globalUserIndices;

  const RankingUserList({
    required this.users,
    required this.teams,
    required this.currentUserId,
    this.scrollToCurrentUser = false,
    this.globalUserIndices = const [],
    Key? key,
  }) : super(key: key);

  Team? _championForUser(AppUser user) {
    return teams.where((team) => team.id == user.championId).firstOrNull;
  }

  int _tipsSetCountForUser({
    required AppUser user,
    required Map<String, List<Tip>> tipsMap,
    required List<CustomMatch> matches,
  }) {
    final userTips = tipsMap[user.id] ?? [];

    return userTips.where((tip) {
      final matchForTip = matches.firstWhere(
        (match) => match.id == tip.matchId,
        orElse: () => CustomMatch.empty(),
      );

      return (tip.tipHome != null || tip.tipGuest != null) &&
          matchForTip.homeScore != null &&
          matchForTip.guestScore != null;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserIndex =
        users.indexWhere((user) => user.id == currentUserId);

    final initialScrollIndex =
        scrollToCurrentUser && currentUserIndex != -1 ? currentUserIndex : 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
      builder: (context, matchState) {
        return BlocBuilder<TipControllerBloc, TipControllerState>(
          builder: (context, tipState) {
            final tipsMap = tipState is TipControllerLoaded
                ? tipState.tips
                : <String, List<Tip>>{};

            final matches = matchState is MatchesControllerLoaded
                ? matchState.matches
                : <CustomMatch>[];

            return ScrollablePositionedList.builder(
              initialScrollIndex: initialScrollIndex,
              itemCount: users.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final user = users[index];
                final isCurrentUser = currentUserId == user.id;
                final champion = _championForUser(user);
                final textTheme = Theme.of(context).textTheme;

                final globalRank = globalUserIndices.isNotEmpty &&
                        index < globalUserIndices.length
                    ? globalUserIndices[index]
                    : index + 1;

                final tipsSetCount = _tipsSetCountForUser(
                  user: user,
                  tipsMap: tipsMap,
                  matches: matches,
                );

                return Container(
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
                        ? _RankingMobileRow(
                            rank: globalRank,
                            user: user,
                            champion: champion,
                            tipsSetCount: tipsSetCount,
                            textTheme: textTheme,
                          )
                        : _RankingDesktopRow(
                            rank: globalRank,
                            user: user,
                            champion: champion,
                            tipsSetCount: tipsSetCount,
                            textTheme: textTheme,
                          ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RankingMobileRow extends StatelessWidget {
  final int rank;
  final AppUser user;
  final Team? champion;
  final int tipsSetCount;
  final TextTheme textTheme;

  const _RankingMobileRow({
    required this.rank,
    required this.user,
    required this.champion,
    required this.tipsSetCount,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '#$rank',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                user.name,
                style:
                    textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${user.score} pkt',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            _ChampionFlag(champion: champion, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _RankingStatIcon(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    value: '${user.jokerSum}',
                    tooltip: 'Joker',
                  ),
                  _RankingStatIcon(
                    icon: Icons.adjust,
                    iconColor: foregroundColor,
                    value: '${user.sixer}',
                    tooltip: '6er',
                  ),
                  _RankingStatIcon(
                    icon: Icons.edit_note,
                    iconColor: foregroundColor,
                    value: '$tipsSetCount',
                    tooltip: 'Tipps',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RankingDesktopRow extends StatelessWidget {
  final int rank;
  final AppUser user;
  final Team? champion;
  final int tipsSetCount;
  final TextTheme textTheme;

  const _RankingDesktopRow({
    required this.rank,
    required this.user,
    required this.champion,
    required this.tipsSetCount,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.white;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            '#$rank',
            style: textTheme.bodyMedium,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            user.name,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ChampionFlag(champion: champion, size: 28),
              const SizedBox(width: 20),
              _RankingStatIcon(
                icon: Icons.star,
                iconColor: Colors.amber,
                value: '${user.jokerSum}',
                tooltip: 'Joker',
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 40,
                child: _RankingStatIcon(
                  icon: Icons.adjust,
                  iconColor: foregroundColor,
                  value: '${user.sixer}',
                  tooltip: '6er',
                ),
              ),
              const SizedBox(width: 20),
              _RankingStatIcon(
                icon: Icons.edit_note,
                iconColor: foregroundColor,
                value: '$tipsSetCount',
                tooltip: 'Tipps',
              ),
              const SizedBox(width: 18),
              SizedBox(
                width: 82,
                child: RichText(
                  textAlign: TextAlign.end,
                  text: TextSpan(
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(text: '${user.score}'),
                      TextSpan(
                        text: ' pkt',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _ChampionFlag extends StatelessWidget {
  final Team? champion;
  final double size;

  const _ChampionFlag({
    required this.champion,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: champion != null ? champion!.name : 'Kein Champion',
      child: SizedBox(
        width: size,
        height: size,
        child: champion != null
            ? ClipOval(
                child: Flag.fromString(
                  champion!.flagCode,
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
                  size: size * 0.58,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }
}

class _RankingStatIcon extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String tooltip;

  const _RankingStatIcon({
    required this.icon,
    required this.iconColor,
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
            size: 14,
            color: iconColor.withOpacity(0.9),
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
