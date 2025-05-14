import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/teams/form/teamsform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/core/buttons/star_icon_button.dart';

class CreateTeamForm extends StatefulWidget {
  const CreateTeamForm({Key? key}) : super(key: key);

  @override
  _CreateTeamFormState createState() => _CreateTeamFormState();
}

class _CreateTeamFormState extends State<CreateTeamForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late String _teamName;
  late String _flagCode;
  late String _id;
  late int _winPoints;
  late bool _champion = false;

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

  String? validateId(String? input) {
    if (input == null || input.trim().isEmpty) {
      return "Bitte geben Sie einen Wert ein";
    } else if (input.trim().length > 3) {
      return "Die Id kann nicht länger als 3 sein";
    } else {
      return null;
    }
  }

  String? validateInt(String? input) {
    if (input == null || input.trim().isEmpty) {
      return "Bitte geb eine Zahl ein";
    }
    if (int.tryParse(input) == null) {
      return "Bitte geb eine gültige ganze Zahl ein";
    }
    if (int.parse(input) < 0) {
      return "Punkte dürfen nicht negativ sein";
    }
    return null;
  }

  String? validateFlagCode(String? input) {
    if (input == null || input.trim().isEmpty) {
      return "Bitte geben Sie einen Wert ein";
    } else if (input.trim().length > 2) {
      return "Der flagcode kann nicht länger als 2 sein";
    } else {
      return null;
    }
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextFormField(
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Team ID / Country Code'),
                  validator: validateId,
                  onChanged: (value) {
                    _id = value;
                  },
                ),
                const SizedBox(height: 16),
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
                TextFormField(
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Win Points'),
                  keyboardType: TextInputType.number,
                  validator: validateInt, // Integer-Validator verwenden
                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      _winPoints = int.parse(value.trim());
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    StarIconButton(
                      isStar: _champion,
                      onTap: () {
                        setState(() {
                          _champion = !_champion;
                        });
                      },
                      size: 30.0,
                      tooltipMessage:
                          _champion ? 'Ist Champion' : 'Ist kein Champion',
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Champion',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
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
                          final Team team = Team(
                              id: _id.toUpperCase(),
                              name: _teamName,
                              flagCode: _flagCode,
                              winPoints: _winPoints,
                              champion: _champion);
                          BlocProvider.of<TeamsformBloc>(context)
                              .add(TeamFormCreateEvent(team: team));
                        } else {
                          BlocProvider.of<TeamsformBloc>(context)
                              .add(TeamFormCreateEvent(team: null));
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
}
