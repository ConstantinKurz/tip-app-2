import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_card_header.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_card_match_info.dart';
import 'widgets/tip_card_input.dart';

class TipCard extends StatefulWidget {
  final String userId;
  final CustomMatch match;
  final Team homeTeam;
  final Team guestTeam;
  final Tip tip;
  final Widget? footer;
  final bool isAdmin;

  const TipCard({
    Key? key,
    required this.userId,
    required this.match,
    required this.homeTeam,
    required this.guestTeam,
    required this.tip,
    this.footer,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<TipCard> {
  late final TextEditingController _homeController;
  late final TextEditingController _guestController;
  Timer? _deadlineTimer;

  @override
  void initState() {
    super.initState();

    _homeController =
        TextEditingController(text: widget.tip.tipHome?.toString() ?? '');
    _guestController =
        TextEditingController(text: widget.tip.tipGuest?.toString() ?? '');

    // Wichtig:
    // DateTime.now() triggert keinen automatischen Rebuild.
    // Deshalb prüfen wir regelmäßig neu, ob die Deadline erreicht ist.
    _deadlineTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _deadlineTimer?.cancel();
    _homeController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  void _updateControllersFromState(TipFormState state) {
    final newHomeValue = state.tipHome?.toString() ?? '';
    final newGuestValue = state.tipGuest?.toString() ?? '';

    if (_homeController.text != newHomeValue) {
      _homeController.text = newHomeValue;
    }

    if (_guestController.text != newGuestValue) {
      _guestController.text = newGuestValue;
    }
  }

  bool _isTipDeadlineReached() {
    if (widget.isAdmin) {
      return false;
    }

    final now = DateTime.now();
    final tipDeadline =
        widget.match.matchDate.subtract(const Duration(minutes: 1));

    // true ab exakt 1 Minute vor Spielbeginn
    return !now.isBefore(tipDeadline);
  }

  bool _canDeleteTip(TipFormState formState) {
    if (formState.tipHome == null || formState.tipGuest == null) {
      return false;
    }

    if (widget.isAdmin) {
      return true;
    }

    final now = DateTime.now();
    final tipDeadline =
        widget.match.matchDate.subtract(const Duration(minutes: 1));

    return now.isBefore(tipDeadline);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResult =
        widget.match.homeScore != null && widget.match.guestScore != null;

    return BlocConsumer<TipFormBloc, TipFormState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting ||
          previous.matchId != current.matchId ||
          previous.tipHome != current.tipHome ||
          previous.tipGuest != current.tipGuest,
      listener: (context, state) {
        if (state.matchId == widget.match.id && !state.isLoading) {
          _updateControllersFromState(state);
        }

        state.failureOrSuccessOption.fold(
          () {},
          (either) => either.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text('❌ Fehler: $failure'),
                ),
              );
            },
            (_) {
              context.read<TipControllerBloc>().add(
                    TipUpdateStatisticsEvent(
                      userId: widget.userId,
                      matchDay: widget.match.matchDay,
                      forceRefresh: true,
                    ),
                  );
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        return previous.joker != current.joker ||
            previous.isLoading != current.isLoading ||
            previous.isSubmitting != current.isSubmitting ||
            previous.matchId != current.matchId ||
            previous.tipHome != current.tipHome ||
            previous.tipGuest != current.tipGuest;
      },
      builder: (context, formState) {
        final isTipDeadlineReached = _isTipDeadlineReached();
        final canDeleteTip = _canDeleteTip(formState);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: formState.joker
                  ? Colors.amber.withOpacity(0.8)
                  : theme.colorScheme.outline.withOpacity(0.1),
              width: formState.joker ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              TipCardHeader(
                match: widget.match,
                tip: widget.tip,
                onDelete: canDeleteTip
                    ? () {
                        final tipId = '${widget.userId}_${widget.match.id}';

                        context.read<TipFormBloc>().add(
                              TipFormDeleteEvent(
                                tipId: tipId,
                                userId: widget.userId,
                                matchDay: widget.match.matchDay,
                              ),
                            );
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              TipCardMatchInfo(
                match: widget.match,
                homeTeam: widget.homeTeam,
                guestTeam: widget.guestTeam,
                hasResult: hasResult,
              ),
              const SizedBox(height: 16),
              TipCardTippingInput(
                homeController: _homeController,
                guestController: _guestController,
                state: formState,
                userId: widget.userId,
                matchId: widget.match.id,
                tip: widget.tip,
                // Normale User: ab 1 Minute vor Spielbeginn read-only.
                // Admins: weiterhin editierbar.
                readOnly: isTipDeadlineReached,
              ),
              if (widget.footer != null) ...[
                const SizedBox(height: 16),
                widget.footer!,
              ],
            ],
          ),
        );
      },
    );
  }
}
