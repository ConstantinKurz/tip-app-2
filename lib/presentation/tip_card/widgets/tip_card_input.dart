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
                        onTap: (homeController.text.isNotEmpty && 
                                guestController.text.isNotEmpty && 
                                !readOnly)
                            ? () {
                                final tipHome = int.tryParse(homeController.text);
                                final tipGuest = int.tryParse(guestController.text);
                                
                                context.read<TipFormBloc>().add(
                                  TipFormFieldUpdatedEvent(
                                    matchId: matchId,
                                    userId: userId,
                                    tipHome: tipHome,
                                    tipGuest: tipGuest,
                                    joker: !(state.joker),
                                    matchDay: state.matchDay,
                                  ),
                                );
                              }
                            : () {},
                        tooltipMessage: readOnly
                            ? "Spiel bereits beendet - keine Änderungen möglich"
                            : (homeController.text.isEmpty || guestController.text.isEmpty)
                                ? "Beide Felder erforderlich"
                                : ((state.joker)
                                    ? "Joker entfernen"
                                    : "Joker setzen"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInput(
    BuildContext context,
    TipFormState state,
    String scoreType,
  ) {
    return SizedBox(
      width: 60,
      height: 56,
      child: TipScoreField(
        controller: scoreType == 'home' ? homeController : guestController,
        otherController: scoreType == 'home' ? guestController : homeController,
        scoreType: scoreType,
        userId: userId,
        matchId: matchId,
        matchDay: state.matchDay,
        readOnly: readOnly,
      ),
    );
  }
}
