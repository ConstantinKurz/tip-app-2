import 'package:flutter/material.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';

class CommunityTipList extends StatelessWidget {
  final List<AppUser> users;
  final Map<String, List<Tip>> allTips;
  final CustomMatch match;
  final String currentUserId;

  const CommunityTipList({
    Key? key,
    required this.users,
    required this.allTips,
    required this.match,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherUsers = users.where((u) => u.id != currentUserId).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
          child: Text(
            'Tipps der Community',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: otherUsers.length,
          separatorBuilder: (_, __) => Divider(
            color: theme.dividerColor.withOpacity(0.05),
            height: 1,
          ),
          itemBuilder: (context, index) {
            final user = otherUsers[index];
            final tip = allTips[user.id]?.firstWhere(
              (t) => t.matchId == match.id,
              orElse: () => Tip.empty(user.id),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User Info mit Name, Joker und 6er
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatItem(context, Icons.star, Colors.amber, '${user.jokerSum}'),
                          const SizedBox(width: 12),
                          _buildStatItem(context, Icons.looks_6, theme.colorScheme.primary, '${user.sixer}'),
                        ],
                      ),
                    ],
                  ),
                  // Tipp und Joker-Stern für dieses Spiel
                  Row(
                    children: [
                      Text(
                        tip != null && tip.tipHome != null
                            ? '${tip.tipHome} : ${tip.tipGuest}'
                            : '–',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: tip != null && tip.tipHome != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      if (tip != null && tip.joker)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, Color color, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}