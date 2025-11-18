import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class RankingUserList extends StatelessWidget {
  final List<AppUser> users;
  final List<Team> teams;
  final String currentUser;

  const RankingUserList({
    required this.users,
    required this.teams,
    required this.currentUser,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Index des aktuellen Users finden
    final currentUserIndex = users.indexWhere((user) => user.id == currentUser);
    final initialScrollIndex = currentUserIndex != -1 ? currentUserIndex : 0;

    return ScrollablePositionedList.builder(
      initialScrollIndex: initialScrollIndex,
      itemCount: users.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = currentUser == user.id;
        final champion = teams.where((element) => element.id == user.championId).firstOrNull;
        final textTheme = Theme.of(context).textTheme;

        return Container(
          decoration: isCurrentUser
              ? BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  child: Text('#${user.rank}', style: textTheme.bodyMedium),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    user.name,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: champion != null ? champion.name : 'None',
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
                            Text('${user.jokerSum}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Text('${user.sixer}',
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                          Text(' 6er', style: textTheme.bodySmall),
                        ],
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
  }
}
