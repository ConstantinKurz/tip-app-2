import 'package:flutter/material.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:intl/intl.dart';

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
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                dateFormat.format(match.matchDate),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        _buildProminentStatus(context, state, theme),
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

  Widget _buildProminentStatus(
      BuildContext context, TipFormState state, ThemeData theme) {
    Widget content;

    if (state.isSubmitting) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Speichert...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      );
    } else {
      content = state.failureOrSuccessOption.fold(
        () => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'Bearbeiten',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        (either) => either.fold(
          (failure) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error,
                size: 14,
                color: Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                'Fehler',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          (success) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Text(
                'Gespeichert',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey<String>(content.toString()),
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: state.isSubmitting
              ? theme.colorScheme.primary.withOpacity(0.1)
              : state.failureOrSuccessOption.fold(
                  () => theme.colorScheme.onSurface.withOpacity(0.1),
                  (either) => either.fold(
                    (_) => Colors.red.withOpacity(0.1),
                    (_) => Colors.green.withOpacity(0.1),
                  ),
                ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: content),
      ),
    );
  }
}
