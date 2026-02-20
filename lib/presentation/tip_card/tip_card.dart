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

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(text: widget.tip.tipHome?.toString() ?? '');
    _guestController = TextEditingController(text: widget.tip.tipGuest?.toString() ?? '');
  }

  @override
  void dispose() {
    _homeController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  // ✅ NEU: Update Controller wenn sich Tips ändern
  void _updateControllersFromState(TipFormState state) {
    // Nur updaten wenn die Werte sich wirklich geändert haben
    final newHomeValue = state.tipHome?.toString() ?? '';
    final newGuestValue = state.tipGuest?.toString() ?? '';
    
    if (_homeController.text != newHomeValue) {
      _homeController.text = newHomeValue;
    }
    
    if (_guestController.text != newGuestValue) {
      _guestController.text = newGuestValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResult = widget.match.homeScore != null && widget.match.guestScore != null;

    return BlocConsumer<TipFormBloc, TipFormState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting ||
          previous.matchId != current.matchId ||
          previous.tipHome != current.tipHome ||
          previous.tipGuest != current.tipGuest,
      listener: (context, state) {
        // ✅ Update Controller wenn Tips vom Stream kommen
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
                      forceRefresh: true, // Stats neu laden nach erfolgreichem Tipp
                    ),
                  );
            },
          ),
        );
      },
      buildWhen: (previous, current) {
        // Rebuild wenn sich relevante Felder ändern
        return previous.joker != current.joker ||
            previous.isLoading != current.isLoading ||
            previous.isSubmitting != current.isSubmitting ||
            previous.matchId != current.matchId;
      },
      builder: (context, formState) {
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
                readOnly: hasResult && !widget.isAdmin,
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
