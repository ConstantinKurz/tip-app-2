import 'package:flutter/material.dart';

class RankingLegendButton extends StatelessWidget {
  const RankingLegendButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      tooltip: 'Legende',
      icon: Icon(
        Icons.help_outline,
        size: 20,
        color: theme.colorScheme.onSurface.withOpacity(0.8),
      ),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Ranglisten-Legende'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendRow(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    title: 'Joker',
                    description: 'Anzahl eingesetzter Joker.',
                  ),
                  SizedBox(height: 12),
                  _LegendRow(
                    icon: Icons.adjust,
                    iconColor: Colors.white,
                    title: '6er',
                    description: 'Anzahl exakter Tipps.',
                  ),
                  SizedBox(height: 12),
                  _LegendRow(
                    icon: Icons.edit_note,
                    iconColor: Colors.white,
                    title: 'Tipps',
                    description:
                        'Anzahl gewerteter Tipps für abgeschlossene Spiele.',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Verstanden',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LegendRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _LegendRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
