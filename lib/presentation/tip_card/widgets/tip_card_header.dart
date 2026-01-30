import 'package:flutter/material.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/usecases/tip_calculator_usecase.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Format: 'Fr, 14.06. 15:00 Uhr' (ohne Punkt nach dem Wochentag)
    final dateFormat = DateFormat('E, dd.MM. HH:mm', 'de_DE');
    String dateString = dateFormat.format(match.matchDate);
    // Entferne Punkt nach Wochentag, falls vorhanden (z.B. 'Fr.' -> 'Fr')
    if (dateString.length > 2 && dateString[2] == '.') {
      dateString = dateString.replaceFirst('.', '');
    }
    final stageName = match.getStageName;
    final stats = state.matchDayStatistics;

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
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  stats != null
                      ? 'Joker: ${stats.jokersUsed}/${stats.jokersAvailable} | Tipps: ${stats.tippedGames}/${stats.totalGames}'
                      : 'Statistiken werden geladen...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
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
            child: Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: match.hasResult && tip.points != null
                    ? '${TipCalculator.getPointsDescription(
                        tipHome: tip.tipHome ?? 0,
                        tipGuest: tip.tipGuest ?? 0,
                        actualHome: match.homeScore ?? 0,
                        actualGuest: match.guestScore ?? 0,
                      )}\nMultiplikator: x${match.phase.pointMultiplier}${tip.joker ? '\nJoker: x2' : ''}'
                    : 'Punkte nach Spielende',
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(text: tip.points != null ? tip.points.toString() : '0'),
                      TextSpan(
                        text: ' pkt',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
