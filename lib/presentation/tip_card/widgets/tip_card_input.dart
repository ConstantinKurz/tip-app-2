import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/core/buttons/star_icon_button.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_score_field.dart';

class TipCardTippingInput extends StatelessWidget {
  final TipFormState state;
  final String userId;
  final String matchId;
  final TextEditingController homeController;
  final TextEditingController guestController;
  final Tip tip;
  final bool readOnly;

  const TipCardTippingInput({
    Key? key,
    required this.state,
    required this.userId,
    required this.matchId,
    required this.homeController,
    required this.guestController,
    required this.tip,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildScoreInput(context, state, 'home'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  ':',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildScoreInput(context, state, 'guest'),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 48,
                      height: 56,
                      child: StarIconButton(
                        isStar: state.joker,
                        onTap: !readOnly && // ✅ Joker nur wenn nicht readOnly
                                ((state.tipHome != null && state.tipGuest != null) ||
                                (state.joker))
                            ? () {
                                context.read<TipFormBloc>().add(
                                  TipFormFieldUpdatedEvent(
                                    matchId: matchId,
                                    userId: userId,
                                    tipHome: state.tipHome,
                                    tipGuest: state.tipGuest,
                                    joker: !(state.joker),
                                    matchDay: state.matchDay,
                                  ),
                                );
                              }
                            : () {},
                        tooltipMessage: readOnly
                            ? "Spiel bereits beendet - keine Änderungen möglich"
                            : ((state.joker) ? "Joker entfernen" : "Joker setzen"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tip.points != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${tip.points}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Punkte',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreInput(
      BuildContext context, TipFormState state, String scoreType) {
    return SizedBox(
      width: 60,
      height: 56,
      child: TipScoreField(
        controller: scoreType == 'home' ? homeController : guestController,
        scoreType: scoreType,
        userId: userId,
        matchId: matchId,
        readOnly: readOnly, // ✅ Parameter weitergeben
      ),
    );
  }
}