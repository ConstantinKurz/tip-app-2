import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';

class DeleteMatchDialog extends StatelessWidget {
  final CustomMatch match;

  const DeleteMatchDialog({
    Key? key,
    required this.match,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return BlocConsumer<MatchesformBloc, MatchesformState>(
      listenWhen: (p, c) =>
          p.matchFailureOrSuccessOption != c.matchFailureOrSuccessOption,
      listener: (context, state) {
        state.matchFailureOrSuccessOption!.fold(
            () {},
            (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold((failure) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text(
                        "Fehler beim Löschen des Matches",
                        style: themeData.textTheme.bodyLarge,
                      )));
                }, (_) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                        "Match gelöscht!",
                        style: themeData.textTheme.bodyLarge,
                      )));
                }));
      },
      builder: (context, state) {
        String contentString =
            "Soll das Match ${match.homeTeamId.value} vs ${match.guestTeamId.value} an Spieltag ${match.matchDay} wirklich gelöscht werden?";
        return AlertDialog(
          content: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(contentString),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        hoverColor: Colors.red,
                        borderColor: Colors.red,
                        buttonText: 'Löschen',
                        callback: () {
                          BlocProvider.of<MatchesformBloc>(context)
                              .add(MatchFormDeleteEvent(id: match.id));
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: CustomButton(
                        hoverColor: primaryDark,
                        borderColor: primaryDark,
                        buttonText: 'Abbrechen',
                        callback: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
