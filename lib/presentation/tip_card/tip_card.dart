import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/match_day_statistics.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_card_header.dart';
import 'widgets/tip_card_input.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResult =
        widget.match.homeScore != null && widget.match.guestScore != null;

    return BlocProvider<TipFormBloc>(
      create: (_) => sl<TipFormBloc>()
        ..add(TipFormInitializedEvent(
          userId: widget.userId,
          matchDay: widget.match.matchDay,
          matchId: widget.match.id,
        )),
      child: BlocConsumer<TipFormBloc, TipFormState>(
        listenWhen: (previous, current) =>
            previous.isSubmitting && !current.isSubmitting,
        listener: (context, state) {
          state.failureOrSuccessOption.fold(
            () {},
            (either) => either.fold(
              (failure) {
                print('❌ Tipp fehlgeschlagen: $failure');
              },
              (_) {
                // ✅ Aktualisiere globale Statistiken nach erfolgreichem Tipp
                context.read<TipControllerBloc>().add(
                      TipUpdateStatisticsEvent(
                        userId: widget.userId,
                        matchDay: widget.match.matchDay,
                      ),
                    );
              },
            ),
          );
        },
        builder: (context, formState) {
          final bool isJokerSet = formState.joker;

          return BlocBuilder<TipControllerBloc, TipControllerState>(
            builder: (context, controllerState) {
              MatchDayStatistics? globalStats;
              if (controllerState is TipControllerLoaded) {
                globalStats =
                    controllerState.matchDayStatistics[widget.match.matchDay];

                // ✅ Lade Statistiken wenn nicht vorhanden
                if (globalStats == null) {
                  print('🔄 Lade Statistiken für matchDay ${widget.match.matchDay}');
                  context.read<TipControllerBloc>().add(
                        TipUpdateStatisticsEvent(
                          userId: widget.userId,
                          matchDay: widget.match.matchDay,
                        ),
                      );
                }
              }

              return Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  children: [
                    TipCardHeader(
                      match: widget.match,
                      tip: widget.tip,
                      stats: globalStats,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
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
                            readOnly: hasResult,
                          ),
                        ],
                      ),
                    ),
                    if (widget.footer != null) widget.footer!,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
