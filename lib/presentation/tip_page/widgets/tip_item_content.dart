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
  final Widget? bottomContent;

  const TipItemContent({
    Key? key,
    required this.userId,
    required this.tip,
    required this.homeTeam,
    required this.guestTeam,
    required this.match,
    this.bottomContent,
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
    homeTipController = TextEditingController(text: widget.tip?.tipHome?.toString() ?? '');
    guestTipController = TextEditingController(text: widget.tip?.tipGuest?.toString() ?? '');
  }

  @override
  void dispose() {
    homeTipController.dispose();
    guestTipController.dispose();
    super.dispose();
  }

  Widget _buildStatusIcon(TipFormState state) {
    const double size = 24;
    final color = Theme.of(context).colorScheme.onPrimaryContainer;

    if (state.isSubmitting) {
      return SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }

    return state.failureOrSuccessOption.fold(
      () => const SizedBox(width: size, height: size),
      (either) => either.fold(
        (_) => const Icon(Icons.close, color: Colors.red, size: size),
        (_) => const Icon(Icons.check, color: Colors.green, size: size),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<TipFormBloc, TipFormState>(
      listener: (_, __) {},
      builder: (context, state) {
        final isHomeTipValid = int.tryParse(homeTipController.text) != null;
        final isGuestTipValid = int.tryParse(guestTipController.text) != null;
        final areTipsValid = isHomeTipValid && isGuestTipValid;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (state.joker ?? false) ? Colors.amber : theme.colorScheme.primaryContainer,
              width: 3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spieltag: ${widget.match.matchDay}, ${DateFormat('dd.MM.yyyy HH:mm').format(widget.match.matchDate)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.tip?.points ?? "0"}',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('pkt', style: theme.textTheme.bodySmall?.copyWith(fontSize: 14)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamColumn(widget.homeTeam),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(message: "Gespeichert?", child: _buildStatusIcon(state)),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(child: TipScoreField(controller: homeTipController, scoreType: 'home', userId: widget.userId, matchId: widget.match.id)),
                                  const SizedBox(width: 8),
                                  Text(":", style: theme.textTheme.bodyLarge),
                                  const SizedBox(width: 8),
                                  Flexible(child: TipScoreField(controller: guestTipController, scoreType: 'guest', userId: widget.userId, matchId: widget.match.id)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            StarIconButton(
                              isStar: state.joker ?? false,
                              onTap: areTipsValid
                                  ? () {
                                      context.read<TipFormBloc>().add(TipFormFieldUpdatedEvent(
                                            matchId: widget.match.id,
                                            userId: widget.userId,
                                            tipHome: state.tipHome,
                                            tipGuest: state.tipGuest,
                                            joker: !(state.joker ?? false),
                                          ));
                                    }
                                  : () {},
                              tooltipMessage: areTipsValid ? "Joker setzen" : "Bitte erst einen gültigen Tipp abgeben",
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Tooltip(
                          message: "Ergebnis",
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(widget.match.homeScore?.toString() ?? '-', style: theme.textTheme.bodyMedium),
                              const SizedBox(width: 8),
                              Text(":", style: theme.textTheme.bodyMedium),
                              const SizedBox(width: 8),
                              Text(widget.match.guestScore?.toString() ?? '-', style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  _buildTeamColumn(widget.guestTeam),
                ],
              ),

              if (widget.bottomContent != null) ...[
                const SizedBox(height: 16),
                widget.bottomContent!,
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamColumn(Team team) {
    final theme = Theme.of(context);
    return Expanded(
      flex: 2,
      child: Column(
        children: [
          ClipOval(
            child: Flag.fromString(team.flagCode, height: 30, width: 30, fit: BoxFit.cover),
          ),
          Text(team.name, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
