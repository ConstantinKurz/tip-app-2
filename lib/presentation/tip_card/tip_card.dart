import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
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
  final TipFormBloc? formBloc; // ✅ Optional pre-created bloc

  const TipCard({
    Key? key,
    required this.userId,
    required this.match,
    required this.homeTeam,
    required this.guestTeam,
    required this.tip,
    this.footer,
    this.formBloc, // ✅ Accept bloc from parent
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResult =
        widget.match.homeScore != null && widget.match.guestScore != null;

    // ✅ If bloc provided from parent (TipPage), use it; otherwise create one
    if (widget.formBloc != null) {
      return BlocProvider<TipFormBloc>.value(
        value: widget.formBloc!,
        child: _TipCardContent(
          theme: theme,
          hasResult: hasResult,
          match: widget.match,
          homeTeam: widget.homeTeam,
          guestTeam: widget.guestTeam,
          tip: widget.tip,
          userId: widget.userId,
          homeController: _homeController,
          guestController: _guestController,
          footer: widget.footer,
        ),
      );
    }

    return BlocProvider<TipFormBloc>(
      create: (_) => sl<TipFormBloc>(),
      child: _TipCardContent(
        theme: theme,
        hasResult: hasResult,
        match: widget.match,
        homeTeam: widget.homeTeam,
        guestTeam: widget.guestTeam,
        tip: widget.tip,
        userId: widget.userId,
        homeController: _homeController,
        guestController: _guestController,
        footer: widget.footer,
      ),
    );
  }
}

class _TipCardContent extends StatelessWidget {
  final ThemeData theme;
  final bool hasResult;
  final CustomMatch match;
  final Team homeTeam;
  final Team guestTeam;
  final Tip tip;
  final String userId;
  final TextEditingController homeController;
  final TextEditingController guestController;
  final Widget? footer;

  const _TipCardContent({
    Key? key,
    required this.theme,
    required this.hasResult,
    required this.match,
    required this.homeTeam,
    required this.guestTeam,
    required this.tip,
    required this.userId,
    required this.homeController,
    required this.guestController,
    required this.footer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TipFormBloc, TipFormState>(
      listenWhen: (previous, current) =>
          previous.isSubmitting && !current.isSubmitting,
      listener: (context, state) {
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
              // ✅ Nach erfolgreichem Speichern: Update Stats
              context.read<TipControllerBloc>().add(
                    TipUpdateStatisticsEvent(
                      userId: userId,
                      matchDay: match.matchDay,
                    ),
                  );
            },
          ),
        );
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
                match: match,
                tip: tip,
              ),
              const SizedBox(height: 12),
              TipCardMatchInfo(
                match: match,
                homeTeam: homeTeam,
                guestTeam: guestTeam,
                hasResult: hasResult,
              ),
              const SizedBox(height: 16),
              TipCardTippingInput(
                homeController: homeController,
                guestController: guestController,
                state: formState,
                userId: userId,
                matchId: match.id,
                tip: tip,
                readOnly: hasResult,
              ),
            ],
          ),
        );
      },
    );
  }
}
