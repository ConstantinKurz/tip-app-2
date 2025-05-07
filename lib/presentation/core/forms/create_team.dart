import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/teams/form/teamsform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';

// Stelle sicher, dass dies die korrekten Imports für deinen TeamsFormBloc sind
// import 'package:flutter_web/application/teams/form/teamsform_event.dart';
// import 'package:flutter_web/application/teams/form/teamsform_state.dart';

class CreateTeamForm extends StatefulWidget {
  const CreateTeamForm({Key? key}) : super(key: key);

  @override
  _CreateTeamFormState createState() => _CreateTeamFormState();
}

class _CreateTeamFormState extends State<CreateTeamForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late String _teamName;
  late String _flagCode;

  String? validateString(String? input) {
    if (input == null || input.trim().isEmpty) {
      return "Bitte geben Sie einen Wert ein";
    } else {
      return null;
    }
  }

  String? validateTeamName(String? input) {
    final validationResult = validateString(input);
    if (validationResult == null) {
      _teamName = input!.trim();
    }
    return validationResult;
  }

  String? validateFlagCode(String? input) {
    final validationResult = validateString(input);
    if (validationResult == null) {
      _flagCode = input!.trim();
    }
    return validationResult;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return BlocConsumer<TeamsformBloc, TeamsformState>(
      listenWhen: (p, c) =>
          p.teamFailureOrSuccessOption != c.teamFailureOrSuccessOption,
      listener: (context, state) {
        state.teamFailureOrSuccessOption?.fold(
            () {},
            (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold((failure) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text(
                        "Fehler beim Erstellen des Teams!",
                        style: themeData.textTheme.bodyLarge,
                      )));
                }, (_) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                        "Team erfolgreich erstellt!",
                        style: themeData.textTheme.bodyLarge,
                      )));
                }));
      },
      builder: (context, state) {
        return Form(
          autovalidateMode: state.showValidationMessages
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          key: formKey,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextFormField(
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Team Name'),
                  validator: validateTeamName,
                  onChanged: (value) => _teamName = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Flag Code (z.B. DE, US)'),
                  validator: validateFlagCode,
                  onChanged: (value) => _flagCode = value,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      buttonText: 'Speichern',
                      backgroundColor: themeData.colorScheme.primaryContainer,
                      borderColor: primaryDark,
                      hoverColor: primaryDark,
                      callback: () {
                        if (formKey.currentState!.validate()) {
                          BlocProvider.of<TeamsformBloc>(context).add(
                              // Hier fügst du das Event zum Erstellen des Teams ein
                              // z.B. TeamFormCreateTeamEvent(name: _teamName, flagCode: _flagCode),
                              // Da es in deinem Code auskommentiert war, lasse ich es so.
                              // Stelle sicher, dass du hier das korrekte Event hinzufügst.
                              // TeamFormCreateTeamEvent(name: _teamName, flagCode: _flagCode),
                              );
                        } else {
                          BlocProvider.of<TeamsformBloc>(context).add(
                              // Füge hier das Event ein, das showValidationMessages im Bloc setzt
                              // z.B. TeamsformEvent.showValidationMessages(),
                              );
                        }
                      },
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    CustomButton(
                      buttonText: 'Abbrechen',
                      backgroundColor: themeData.colorScheme.primaryContainer,
                      borderColor: primaryDark,
                      hoverColor: primaryDark,
                      callback: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                )
              ]),
        );
      },
    );
  }
} // Fehlende schließende Klammer hier hinzugefügt
