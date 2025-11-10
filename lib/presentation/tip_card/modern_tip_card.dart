import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_card_header.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_card_input.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_card_match_info.dart';

class TipCard extends StatefulWidget {
  final String userId;
  final CustomMatch match;
  final Team homeTeam;
  final Team guestTeam;
  final Tip tip;
  final Widget? footer;

  const TipCard({
    Key? key,
    required this.userId,
    required this.match,
    required this.homeTeam,
    required this.guestTeam,
    required this.tip,
    this.footer,
  }) : super(key: key);

  @override
  State<TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<TipCard> {
  late final TextEditingController _homeController;
  late final TextEditingController _guestController;

  @override
  void initState() {
    super.initState();
    _homeController =
        TextEditingController(text: widget.tip.tipHome?.toString() ?? '');
    _guestController =
        TextEditingController(text: widget.tip.tipGuest?.toString() ?? '');
  }

  @override
  void dispose() {
    _homeController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  bool get _isMatchFinished {
    final matchEndTime =
        widget.match.matchDate.add(const Duration(minutes: 150));
    return DateTime.now().isAfter(matchEndTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResult =
        widget.match.homeScore != null && widget.match.guestScore != null;

    return BlocProvider<TipFormBloc>(
      create: (_) =>
          sl<TipFormBloc>()..add(TipFormInitializedEvent(tip: widget.tip)),
      child: BlocConsumer<TipFormBloc, TipFormState>(
        buildWhen: (previous, current) {
          if (previous.isSubmitting != current.isSubmitting) return true;
          if (previous.joker != current.joker) return true;
          return false;
        },
        listenWhen: (previous, current) {
          return previous.isSubmitting && !current.isSubmitting;
        },
        listener: (context, state) {
          state.failureOrSuccessOption.fold(
            () {},
            (either) => either.fold(
              (failure) {
                _homeController.text = state.tipHome?.toString() ?? '';
                _guestController.text = state.tipGuest?.toString() ?? '';
              },
              (_) {},
            ),
          );
        },
        builder: (context, state) {
          final bool isJokerSet = state.joker ?? false;

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isJokerSet
                    ? Colors.amber.withOpacity(0.8)
                    : theme.colorScheme.outline.withOpacity(0.1),
                width: isJokerSet ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isJokerSet
                      ? Colors.amber.withOpacity(0.15)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TipCardHeader(
                    match: widget.match,
                    state: state,
                    isMatchFinished: _isMatchFinished,
                  ),
                  const SizedBox(height: 16),
                  TipCardMatchInfo(
                    match: widget.match,
                    homeTeam: widget.homeTeam,
                    guestTeam: widget.guestTeam,
                    hasResult: hasResult,
                  ),
                  const SizedBox(height: 16),
                  TipCardTippingInput(
                    state: state,
                    userId: widget.userId,
                    matchId: widget.match.id,
                    homeController: _homeController,
                    guestController: _guestController,
                    tip: widget.tip,
                  ),
                  if (widget.footer != null) widget.footer!,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
