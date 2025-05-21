import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
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
          ),
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
                  SizedBox(
                    width: 50,
                    child: TextFormField(
                        textAlign: TextAlign.center,
                        controller: homeTipController,
                        style: themeData.textTheme.bodyLarge,
                        cursorColor: themeData.colorScheme.primaryContainer,
                        validator: (value) =>
                            _validateScore(value, state, 'home'),
                        maxLength: 2,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: themeData.colorScheme.primaryContainer
                              .withOpacity(.2),
                          counterText: "",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) => {
                              context.read<TipFormBloc>().add(
                                    TipFormFieldUpdatedEvent(
                                      matchId: widget.match.id,
                                      userId: widget.userId,
                                      tipGuest: state.tipGuest,
                                      tipHome: int.tryParse(value),
                                    ),
                                  ),
                            }),
                  ),
                  const SizedBox(width: 16),
                  Text(":", style: themeData.textTheme.bodyLarge),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 50,
                    child: TextFormField(
                      textAlign: TextAlign.center,
                      controller: guestTipController,
                      style: themeData.textTheme.bodyLarge,
                      cursorColor: themeData.colorScheme.primaryContainer,
                      validator: (value) =>
                          _validateScore(value, state, 'guest'),
                      maxLength: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: themeData.colorScheme.primaryContainer
                            .withOpacity(.2),
                        counterText: "",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => {
                        context
                            .read<TipFormBloc>()
                            .add(TipFormFieldUpdatedEvent(
                              matchId: widget.match.id,
                              userId: widget.userId,
                              tipGuest: int.tryParse(value),
                              tipHome: state.tipHome,
                            ))
                      },
                    ),
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
