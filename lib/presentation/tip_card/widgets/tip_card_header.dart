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
  final VoidCallback? onDelete;

  const TipCardHeader({
    Key? key,
    required this.match,
    required this.tip,
    this.showStatus,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateString = _formatDate(match.matchDate);
    final stageName = match.getStageName;

    // ✅ NEU: Hole Stats UND aktuelle Punkte aus TipControllerBloc
    return BlocBuilder<TipControllerBloc, TipControllerState>(
      buildWhen: (previous, current) {
        // Immer rebuild bei State-Typ-Wechsel
        if (previous.runtimeType != current.runtimeType) return true;
        
        // Bei Loaded-States: Rebuild wenn Stats ODER Punkte sich ändern
        if (previous is TipControllerLoaded && current is TipControllerLoaded) {
          final prevStats = previous.matchDayStatistics[match.matchDay];
          final currStats = current.matchDayStatistics[match.matchDay];
          
          // ✅ FIX: Auch prüfen ob sich die Punkte für diesen Tip geändert haben
          final prevTips = previous.tips[tip.userId] ?? [];
          final currTips = current.tips[tip.userId] ?? [];
          final prevTip = prevTips.firstWhere((t) => t.matchId == match.id, orElse: () => tip);
          final currTip = currTips.firstWhere((t) => t.matchId == match.id, orElse: () => tip);
          
          return prevStats != currStats || prevTip.points != currTip.points;
        }
        
        return true;
      },
      builder: (context, tipState) {
        final stats = (tipState is TipControllerLoaded)
            ? tipState.matchDayStatistics[match.matchDay]
            : null;
        
        // ✅ FIX: Hole aktuellen Tip mit Punkten aus dem State
        Tip currentTip = tip;
        if (tipState is TipControllerLoaded) {
          final userTips = tipState.tips[tip.userId] ?? [];
          currentTip = userTips.firstWhere(
            (t) => t.matchId == match.id,
            orElse: () => tip,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Erste Zeile: Phase | Status | Delete Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    stageName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const Expanded(
                  child: Center(child: TipStatus()),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: onDelete != null
                        ? _DeleteTipButton(onTap: onDelete!)
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Zweite Zeile: Stats + Punkte
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats != null
                            ? 'Joker: ${stats.jokersUsed}/${stats.jokersAvailable} | Tipps: ${stats.tippedGames}/${stats.totalGames}'
                            : 'Statistiken werden geladen...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                Tooltip(
                  message: match.hasResult && currentTip.points != null
                      ? '${TipCalculator.getPointsDescription(
                          tipHome: currentTip.tipHome ?? 0,
                          tipGuest: currentTip.tipGuest ?? 0,
                          actualHome: match.homeScore ?? 0,
                          actualGuest: match.guestScore ?? 0,
                        )}\nMultiplikator: x${match.phase.pointMultiplier}${currentTip.joker ? '\nJoker: x2' : ''}'
                      : 'Punkte nach Spielende',
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: currentTip.points != null ? '${currentTip.points}' : '0',
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
              ],
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

/// Dezenter Delete-Button mit Hover-Effekt
class _DeleteTipButton extends StatefulWidget {
  final VoidCallback onTap;

  const _DeleteTipButton({
    required this.onTap,
  });

  @override
  State<_DeleteTipButton> createState() => _DeleteTipButtonState();
}

class _DeleteTipButtonState extends State<_DeleteTipButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color iconColor = _isHovered 
        ? theme.colorScheme.error 
        : theme.colorScheme.outline;
    final Color? backgroundColor = _isHovered
        ? theme.colorScheme.error.withOpacity(0.1)
        : null;

    return Tooltip(
      message: 'Tipp entfernen',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.delete_outline,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
