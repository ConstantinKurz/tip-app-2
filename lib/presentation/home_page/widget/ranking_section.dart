import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';

class RankingSection extends StatefulWidget {
  final List<AppUser> users;
  final List<Team> teams;

  const RankingSection({required this.users, required this.teams, Key? key})
      : super(key: key);

  @override
  State<RankingSection> createState() => _RankingSectionState();
}

class _RankingSectionState extends State<RankingSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final sortedUsers = [...widget.users]
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 30.0,
          ),
          const SizedBox(
            width: 12,
          ),
          Text(
            'Ranking',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ]),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          firstChild:
              _buildUserList(sortedUsers.take(2).toList(), widget.teams),
          secondChild: _buildUserList(sortedUsers, widget.teams),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
        if (sortedUsers.length > 2)
          Center(
            child: IconButton(
              icon: Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: themeData.primaryIconTheme.color,
              ),
              onPressed: () {
                setState(() {
                  expanded = !expanded;
                });
              },
              tooltip: expanded ? 'Weniger anzeigen' : 'Mehr anzeigen',
            ),
          ),
      ],
    );
  }
}

Widget _buildUserList(List<AppUser> users, List<Team> teams) {
  return ListView.builder(
    itemCount: users.length,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (context, index) {
      final user = users[index];
      final champion =
          teams.where((element) => element.id == user.championId).firstOrNull;
      final textTheme = Theme.of(context).textTheme;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                user.username,
                style:
                    textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
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
                        : const ClipOval(
                            child:
                                Icon(Icons.close, size: 20, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 24),
                  Row(
                      // crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('${user.jokerSum}',
                            style: textTheme.displayLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Icon(Icons.star, size: 20, color: Colors.amber),
                        ),
                      ]),
                  const SizedBox(width: 24),
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('${user.score}',
                            style: textTheme.displayLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(width: 4),
                        Text('pkt',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 14,
                            )),
                      ])
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
