import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/teams/form/teamsform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';

class DeleteTeamDialog extends StatelessWidget {
  final Team team;

  const DeleteTeamDialog({
    Key? key,
    required this.team,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final String contentString =
        "Soll das Team ${team.name} wirklich gelöscht werden?";

    return BlocConsumer<TeamsformBloc, TeamsformState>(
      listenWhen: (p, c) =>
          p.teamFailureOrSuccessOption != c.teamFailureOrSuccessOption,
      listener: (context, state) {
        state.teamFailureOrSuccessOption?.fold(
          () {},
          (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text(
                  "Fehler beim Löschen des Teams",
                  style: themeData.textTheme.bodyLarge,
                ),
              ));
            },
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                  "Team gelöscht!",
                  style: themeData.textTheme.bodyLarge,
                ),
              ));
            },
          ),
        );
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contentString, style: const TextStyle(color: Colors.white)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  backgroundColor: themeData.colorScheme.primaryContainer,
                  hoverColor: Colors.red,
                  borderColor: Colors.red,
                  buttonText: 'Löschen',
                  callback: () {
                    BlocProvider.of<TeamsformBloc>(context)
                        .add(TeamFormDeleteEvent(id: team.id));
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
