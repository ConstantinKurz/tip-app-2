import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/usecases/tip_calculator_usecase.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_status.dart';

class TipCardHeader extends StatelessWidget {
  final CustomMatch match;
  final Tip tip;
  final bool? showStatus;

  const TipCardHeader(
      {Key? key, required this.match, required this.tip, this.showStatus})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateString = _formatDate(match.matchDate);
    final stageName = match.getStageName;

    // ✅ NEU: Hole Stats aus TipControllerBloc, nicht TipFormBloc
    return BlocBuilder<TipControllerBloc, TipControllerState>(
      buildWhen: (previous, current) {
        // Nur rebuild wenn Stats sich ändern
        final prevStats = (previous is TipControllerLoaded)
            ? previous.matchDayStatistics[match.matchDay]
            : null;
        final currStats = (current is TipControllerLoaded)
            ? current.matchDayStatistics[match.matchDay]
            : null;

        return prevStats != currStats;
      },
      builder: (context, tipState) {
        final stats = (tipState is TipControllerLoaded)
            ? tipState.matchDayStatistics[match.matchDay]
            : null;

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
            const TipStatus(),
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
                          TextSpan(
                            text: tip.points != null ? '${tip.points}' : '0',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' pkt',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez'
    ];
    final days = ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'];

    final day = days[dateTime.weekday % 7];
    final date = dateTime.day;
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day, $date.$month. $hour:$minute';
  }
}
