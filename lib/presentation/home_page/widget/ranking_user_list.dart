import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
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

  @override
  Widget build(BuildContext context) {
    // Index des aktuellen Users finden
    final currentUserIndex =
        users.indexWhere((user) => user.id == currentUserId);
    final initialScrollIndex =
        (scrollToCurrentUser && currentUserIndex != -1) ? currentUserIndex : 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
      builder: (context, matchState) {
        return BlocBuilder<TipControllerBloc, TipControllerState>(
          builder: (context, tipState) {
            final tipsMap = tipState is TipControllerLoaded ? tipState.tips : <String, List<dynamic>>{};
            final matches = matchState is MatchesControllerLoaded ? matchState.matches : [];

        return ScrollablePositionedList.builder(
      initialScrollIndex: initialScrollIndex,
      itemCount: users.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final user = users[index];
            final userTips = tipsMap[user.id] ?? [];
            // Zähle nur Tipps von Matches mit Ergebnis (abgeschlossen)
            final tipsSetCount = userTips.where((t) {
              final matchForTip = matches.firstWhere(
                (m) => m.id == t.matchId,
                orElse: () => CustomMatch.empty(),
              );
              return (t.tipHome != null || t.tipGuest != null) &&
                  matchForTip != null &&
                  matchForTip.homeScore != null &&
                  matchForTip.guestScore != null;
            }).length;
        final isCurrentUser = currentUserId == user.id;
        final champion =
            teams.where((element) => element.id == user.championId).firstOrNull;
        final textTheme = Theme.of(context).textTheme;
        final globalRank =
          globalUserIndices.isNotEmpty && index < globalUserIndices.length
            ? globalUserIndices[index]
            : index + 1;

        return Container(
          decoration: isCurrentUser
              ? BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: isMobile
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First row: Rank + Name + Score
                      Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '#$globalRank',
                              style: textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              user.name,
                              style: textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${user.score}p',
                            style: textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Second row: Champion flag + Joker + 6er
                      Row(
                        children: [
                          Tooltip(
                            message: champion != null ? champion.name : 'None',
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: champion != null
                                  ? ClipOval(
                                      child: Flag.fromString(
                                        champion.flagCode,
                                        height: 24,
                                        width: 24,
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
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text('${user.jokerSum}⭐',
                                style: textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text('${user.sixer}×6',
                                style: textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text('$tipsSetCount ${tipsSetCount == 1 ? 'Tipp' : 'Tipps'}',
                                style: textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        child:
                            Text('#$globalRank', style: textTheme.bodyMedium),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          user.name,
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Tooltip(
                              message:
                                  champion != null ? champion.name : 'None',
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: champion != null
                                    ? ClipOval(
                                        child: Flag.fromString(
                                          champion.flagCode,
                                          height: 28,
                                          width: 28,
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
                              width: 48,
                              child: Row(
                                children: [
                                  Text(
                                    '${user.jokerSum}',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.star,
                                      size: 14, color: Colors.amber),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 48,
                              child: Row(
                                children: [
                                  Text(
                                    '${user.sixer}',
                                    style: textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(' 6er', style: textTheme.bodySmall),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 64,
                              child: Text(
                                '$tipsSetCount ${tipsSetCount == 1 ? 'Tipp' : 'Tipps'}',
                                style: textTheme.bodySmall,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: Text(
                                '${user.score}',
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
