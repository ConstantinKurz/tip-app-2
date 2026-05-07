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
    final String contentString =
        "Soll das Match ${match.homeTeamId} vs ${match.guestTeamId} an Spieltag ${match.matchDay} wirklich gelöscht werden?";

    return BlocConsumer<MatchesformBloc, MatchesformState>(
      listenWhen: (p, c) =>
          p.matchFailureOrSuccessOption != c.matchFailureOrSuccessOption,
      listener: (context, state) {
        state.matchFailureOrSuccessOption?.fold(
          () {},
          (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text(
                  "Fehler beim Löschen des Matches",
                  style: themeData.textTheme.bodyLarge,
                ),
              ));
            },
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                  "Match gelöscht!",
                  style: themeData.textTheme.bodyLarge,
                ),
              ));
            },
          ),
        );
      },
      builder: (context, state) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contentString, style: const TextStyle(color: Colors.white)),
            const Spacer(),
            isMobile
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          backgroundColor:
                              themeData.colorScheme.primaryContainer,
                          hoverColor: Colors.red,
                          borderColor: Colors.red,
                          buttonText: 'Löschen',
                          callback: () {
                            BlocProvider.of<MatchesformBloc>(context)
                                .add(MatchFormDeleteEvent(id: match.id));
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          backgroundColor:
                              themeData.colorScheme.primaryContainer,
                          hoverColor: primaryDark,
                          borderColor: primaryDark,
                          buttonText: 'Abbrechen',
                          callback: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomButton(
                        backgroundColor: themeData.colorScheme.primaryContainer,
                        hoverColor: Colors.red,
                        borderColor: Colors.red,
                        buttonText: 'Löschen',
                        callback: () {
                          BlocProvider.of<MatchesformBloc>(context)
                              .add(MatchFormDeleteEvent(id: match.id));
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8.0),
                      CustomButton(
                        backgroundColor: themeData.colorScheme.primaryContainer,
                        hoverColor: primaryDark,
                        borderColor: primaryDark,
                        buttonText: 'Abbrechen',
                        callback: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
            const SizedBox(
              height: 16,
            )
          ],
        );
      },
    );
  }
}
