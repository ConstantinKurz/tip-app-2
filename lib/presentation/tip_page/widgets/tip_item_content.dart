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

  String? _validateScore(String? value, TipFormState state, String scoreType) {
    if (value == null || value.isEmpty) {
      if ((state.tipHome == null && scoreType == 'guest') ||
          (state.tipGuest == null && scoreType == 'home')) {
        return '[0-10]';
      }
      return null;
    }
    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0 || intValue > 10) {
      return '[0-10]';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return BlocConsumer<TipFormBloc, TipFormState>(
      listener: (context, state) {
        state.failureOrSuccessOption.fold(
          () {},
          (either) => either.fold(
            (failure) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text(
                  "Fehler beim Aktualisieren des Tipps",
                  style: themeData.textTheme.bodyLarge,
                ),
              ),
            ),
            (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                  "Tipp erfolgreich aktualisiert!",
                  style: themeData.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        );
      },
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              color: themeData.colorScheme.onPrimaryContainer,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                  color: (state.joker ?? false)
                      ? Colors.amber
                      : themeData.colorScheme.primary,
                  width: 3)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spieltag: ${widget.match.matchDay}, ${DateFormat('dd.MM.yyyy HH:mm').format(widget.match.matchDate)}',
                style: themeData.textTheme.bodySmall,
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Spacer(),
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
                  const SizedBox(width: 16.0),
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
                  const SizedBox(width: 16.0),
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
                  const Spacer(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
