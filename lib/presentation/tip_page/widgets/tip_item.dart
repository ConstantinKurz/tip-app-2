import 'package:dartz/dartz.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:intl/intl.dart';

class TipItem extends StatelessWidget {
  final String userId;
  final Tip? tip;
  final Team homeTeam;
  final Team guestTeam;
  final CustomMatch match;
  final TextEditingController homeTipController = TextEditingController();
  final TextEditingController guestTipController = TextEditingController();
  TipItem(
      {Key? key,
      this.tip,
      required this.userId,
      required this.homeTeam,
      required this.guestTeam,
      required this.match})
      : super(key: key) {
    homeTipController.text = tip?.tipHome?.toString() ?? '';
    guestTipController.text = tip?.tipGuest?.toString() ?? '';
  }

  String? _validateScore(String? value, TipFormState state,
      BuildContext context, String scoreType) {
    if (value == null || value.isEmpty) {
      // Access the other score from the state
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
    // No need to update local score variables, the bloc will handle it
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return BlocConsumer<TipFormBloc, TipFormState>(
      listener: (context, state) {
        state.failureOrSuccessOption!.fold(
          () {},
          (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(
                    "Fehler beim Aktualisieren des Tipps",
                    style: themeData.textTheme.bodyLarge,
                  ),
                ),
              );
            },
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(
                    "Tip erfolgreich aktualisiert!",
                    style: themeData.textTheme.bodyLarge,
                  ),
                ),
              );
            },
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
              // Spieltag und Spielzeit oben links
              Text(
                'Spieltag:${match.matchDay}, ${DateFormat('dd.MM.yyyy HH:mm').format(match.matchDate)}',
                style: themeData.textTheme.bodySmall,
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Spacer(),
                  // Heimteam
                  Expanded(
                    child: Column(
                      children: [
                        ClipOval(
                          child: Flag.fromString(
                            homeTeam.flagCode,
                            height: 30,
                            width: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(
                          homeTeam.name,
                          style: themeData.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  // Heim- und Gastscore nebeneinander
                  SizedBox(
                    width: 50,
                    child: TextFormField(
                      textAlign: TextAlign.center,
                      controller: homeTipController,
                      style: themeData.textTheme.bodyLarge,
                      cursorColor: themeData.colorScheme.primaryContainer,
                      validator: (value) =>
                          _validateScore(value, state, context, 'home'),
                      maxLength: 2,
                      maxLines: 1,
                      minLines: 1,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: themeData.colorScheme.primaryContainer
                            .withOpacity(.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => context.read<TipFormBloc>().add(
                          TipFormFieldUpdatedEvent(
                              matchId: match.id,
                              userId: userId,
                              tipGuest: state.tipGuest,
                              tipHome: int.tryParse(value))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    ":",
                    style: themeData.textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 50,
                    child: TextFormField(
                      textAlign: TextAlign.center,
                      controller: guestTipController,
                      style: themeData.textTheme.bodyLarge,
                      cursorColor: themeData.colorScheme.primaryContainer,
                      validator: (value) =>
                          _validateScore(value, state, context, 'guest'),
                      maxLength: 2,
                      maxLines: 1,
                      minLines: 1,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: themeData.colorScheme.primaryContainer
                            .withOpacity(.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => context.read<TipFormBloc>().add(
                          TipFormFieldUpdatedEvent(
                              matchId: match.id,
                              userId: userId,
                              tipGuest: int.tryParse(value),
                              tipHome: state.tipHome)),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  // Gastteam
                  Expanded(
                    child: Column(
                      children: [
                        ClipOval(
                          child: Flag.fromString(
                            guestTeam.flagCode,
                            height: 30,
                            width: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(
                          guestTeam.name,
                          style: themeData.textTheme.bodyLarge,
                        ),
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
