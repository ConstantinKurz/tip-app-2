import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';

class RankingUserList extends StatelessWidget {
  final List<AppUser> users;
  final List<Team> teams;
  final String currentUser;
  const RankingUserList(
      {required this.users,
      required this.teams,
      required this.currentUser,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = currentUser == user.username;
        final champion =
            teams.where((element) => element.id == user.championId).firstOrNull;
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
                    user.username,
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
                              : const ClipOval(
                                  child: Icon(Icons.close,
                                      size: 20, color: Colors.grey),
                                ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Row(textBaseline: TextBaseline.alphabetic, children: [
                        Text('${user.jokerSum}',
                            style: textTheme.displayLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Tooltip(
                              message: 'Joker',
                              child: Icon(Icons.star,
                                  size: 20, color: Colors.amber)),
                        ),
                      ]),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 100,
                        child: RichText(
                          textAlign: TextAlign.end,
                          text: TextSpan(
                            style: textTheme.displayMedium?.copyWith(
                              fontSize: 24,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(text: '${user.score}'),
                              TextSpan(
                                text: ' pkt',
                                style:
                                    textTheme.bodySmall?.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
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
