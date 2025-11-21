import 'package:flutter/material.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:intl/intl.dart';

import 'tip_status.dart';

class TipCardHeader extends StatelessWidget {
  final CustomMatch match;
  final TipFormState state;
  final Tip tip;

  const TipCardHeader({
    Key? key,
    required this.match,
    required this.state,
    required this.tip,
  }) : super(key: key);

  String _getStageName(int matchDay) {
    if (matchDay <= 3) {
      return 'Gruppenphase, Tag $matchDay';
    }
    switch (matchDay) {
      case 4:
        return 'Achtelfinale';
      case 5:
        return 'Viertelfinale';
      case 6:
        return 'Halbfinale';
      case 7:
        return 'Finale';
      default:
        return 'Spieltag $matchDay';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('E, dd.MM. HH:mm', 'de_DE');
    final stageName = _getStageName(match.matchDay);
    final dateString = dateFormat.format(match.matchDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stageName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                '$dateString Uhr',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        TipStatus(state: state),
        Expanded(
          child: SizedBox(
            width: 100,
            child: RichText(
              textAlign: TextAlign.end,
              text: TextSpan(
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(text: '${tip.points ?? 0}'),
                  TextSpan(
                    text: ' pkt',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
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
