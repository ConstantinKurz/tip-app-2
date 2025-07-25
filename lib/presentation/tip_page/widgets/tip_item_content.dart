import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/core/buttons/star_icon_button.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_score_field.dart';
import 'package:intl/intl.dart';
import 'package:flag/flag.dart';

class TipItemContent extends StatefulWidget {
  final String userId;
  final Tip? tip;
  final Team homeTeam;
  final Team guestTeam;
  final CustomMatch match;

  const TipItemContent({
    Key? key,
    required this.userId,
    required this.tip,
    required this.homeTeam,
    required this.guestTeam,
    required this.match,
  }) : super(key: key);

  @override
  State<TipItemContent> createState() => _TipItemContentState();
}

class _TipItemContentState extends State<TipItemContent> {
  late final TextEditingController homeTipController;
  late final TextEditingController guestTipController;

  @override
  void initState() {
    super.initState();
    homeTipController =
        TextEditingController(text: widget.tip?.tipHome?.toString() ?? '');
    guestTipController =
        TextEditingController(text: widget.tip?.tipGuest?.toString() ?? '');
  }

  @override
  void dispose() {
    homeTipController.dispose();
    guestTipController.dispose();
    super.dispose();
  }

// todo: add jokercheck here
  Widget _buildStatusIcon(TipFormState state) {
    final themeData = Theme.of(context);
    const double statusIconSize = 24;
    if (state.isSubmitting) {
      return  SizedBox(
        height: statusIconSize,
        width: statusIconSize,
        child: CircularProgressIndicator(strokeWidth: 2, color: themeData.colorScheme.onPrimaryContainer,),
      );
    }

    return state.failureOrSuccessOption.fold(
      () => const SizedBox(
        height: statusIconSize,
        width: statusIconSize,
      ),
      (either) => either.fold(
        (_) => const Icon(Icons.close, color: Colors.red, size: statusIconSize),
        (_) =>
            const Icon(Icons.check, color: Colors.green, size: statusIconSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //Todo: add is preview bool for preview on home page
    final themeData = Theme.of(context);

    return BlocConsumer<TipFormBloc, TipFormState>(
      listener: (context, state) {
        state.failureOrSuccessOption.fold(
          () {},
          (either) {},
        );
      },
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              color: themeData.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                  color: (state.joker ?? false)
                      ? Colors.amber
                      : themeData.colorScheme.primaryContainer,
                  width: 3)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  'Spieltag: ${widget.match.matchDay}, ${DateFormat('dd.MM.yyyy HH:mm').format(widget.match.matchDate)}',
                  style: themeData.textTheme.bodyMedium,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${widget.tip?.points ?? "0"}',
                      style: themeData.textTheme.displayLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'pkt',
                      style: themeData.textTheme.bodySmall?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              ]),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  // const Spacer(),
                  Expanded(
                    child: Column(
                      children: [
                        ClipOval(
                          child: Flag.fromString(
                            widget.homeTeam.flagCode,
                            height: 30,
                            width: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(widget.homeTeam.name,
                            style: themeData.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  Tooltip(
                      message: "Gespeichert?", child: _buildStatusIcon(state)),
                  const SizedBox(width: 32.0),
                  Column(
                    children: [
                      Row(
                        children: [
                          TipScoreField(
                            controller: homeTipController,
                            scoreType: 'home',
                            userId: widget.userId,
                            matchId: widget.match.id,
                          ),
                          const SizedBox(width: 16),
                          Text(":", style: themeData.textTheme.bodyLarge),
                          const SizedBox(width: 16),
                          TipScoreField(
                            controller: guestTipController,
                            scoreType: 'guest',
                            userId: widget.userId,
                            matchId: widget.match.id,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Tooltip(
                        message: 'Ergebnis',
                        child: Row(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    widget.match.homeScore != null
                                        ? widget.match.homeScore.toString()
                                        : '-',
                                    style: themeData.textTheme.bodyMedium),
                                const SizedBox(width: 16),
                                Text(":",
                                    style: themeData.textTheme.bodyMedium),
                                const SizedBox(width: 16),
                                Text(
                                    widget.match.guestScore != null
                                        ? widget.match.guestScore.toString()
                                        : '-',
                                    style: themeData.textTheme.bodyMedium),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 32.0),
                  StarIconButton(
                    isStar: state.joker ?? false,
                    onTap: () {
                      context.read<TipFormBloc>().add(
                            TipFormFieldUpdatedEvent(
                              matchId: widget.match.id,
                              userId: widget.userId,
                              tipHome: state.tipHome,
                              tipGuest: state.tipGuest,
                              joker: !(state.joker ?? false),
                            ),
                          );
                    },
                    tooltipMessage: "Joker setzen",
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        ClipOval(
                          child: Flag.fromString(
                            widget.guestTeam.flagCode,
                            height: 30,
                            width: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(widget.guestTeam.name,
                            style: themeData.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
