import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/form/authform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';

class UpdateUserForm extends StatelessWidget {
  final AppUser user;
  final List<Team> teams;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController rankController = TextEditingController();
  final TextEditingController scoreController = TextEditingController();
  final TextEditingController jokerSumController = TextEditingController();
  final TextEditingController championIdController = TextEditingController();
  final TextEditingController sixerController = TextEditingController();

  UpdateUserForm({Key? key, required this.user, required this.teams})
      : super(key: key);

  String? _validateString(String? value) {
    if (value == null || value.isEmpty) {
      return "Bitte geben Sie einen Wert ein";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    const emailRegex =
        r"""^[a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";
    if (value == null || value.isEmpty) {
      return "Gebe eine Mail ein";
    } else if (!RegExp(emailRegex).hasMatch(value)) {
      return "Keine gültige E-Mail";
    }
    return null;
  }

  String? _validateInt(String? value) {
    if (value == null || value.isEmpty) {
      return "Bitte geben Sie einen Wert ein";
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return "Bitte geben Sie eine gültige Zahl ein";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    usernameController.text = user.name;
    rankController.text = user.rank.toString();
    scoreController.text = user.score.toString();
    jokerSumController.text = user.jokerSum.toString();
    championIdController.text = user.championId;
    sixerController.text = user.sixer.toString();

    return BlocConsumer<AuthformBloc, AuthformState>(
      listenWhen: (previous, current) =>
          previous.authFailureOrSuccessOption !=
          current.authFailureOrSuccessOption,
      listener: (context, state) {
        state.authFailureOrSuccessOption!.fold(
          () {},
          (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(
                    "Fehler beim Aktualisieren des Benutzers",
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
                    "Benutzer erfolgreich aktualisiert!",
                    style: themeData.textTheme.bodyLarge,
                  ),
                ),
              );
              Navigator.of(context).pop();
            },
          ),
        );
      },
      builder: (context, state) {
        return SingleChildScrollView(
          child: Form(
            autovalidateMode: state.showValidationMessages
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  validator: _validateString,
                  decoration: InputDecoration(
                    labelText: "Benutzername",
                    hintText: user.name,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => context
                      .read<AuthformBloc>()
                      .add(UserFormFieldUpdatedEvent(username: value)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: rankController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  validator: _validateInt,
                  decoration: InputDecoration(
                    labelText: "Rang",
                    hintText: user.rank.toString(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => context
                      .read<AuthformBloc>()
                      .add(UserFormFieldUpdatedEvent(rank: int.tryParse(value))),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: scoreController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  validator: _validateInt,
                  decoration: InputDecoration(
                    labelText: "Punkte",
                    hintText: user.score.toString(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => context
                      .read<AuthformBloc>()
                      .add(UserFormFieldUpdatedEvent(score: int.tryParse(value))),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: jokerSumController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  validator: _validateInt,
                  decoration: InputDecoration(
                    labelText: "Joker Summe",
                    hintText: user.jokerSum.toString(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => context
                      .read<AuthformBloc>()
                      .add(UserFormFieldUpdatedEvent(jokerSum: int.tryParse(value))),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: sixerController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  validator: _validateInt,
                  decoration: InputDecoration(
                    labelText: "Sechser",
                    hintText: user.sixer.toString(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => context
                      .read<AuthformBloc>()
                      .add(UserFormFieldUpdatedEvent(sixer: int.tryParse(value))),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: teams.any((t) => t.id == state.championId)
                      ? state.championId
                      : null,
                  decoration: const InputDecoration(labelText: 'Champion'),
                  items: teams
                      .map((team) => DropdownMenuItem<String>(
                            value: team.id,
                            child: Text(team.name),
                          ))
                      .toList(),
                  onChanged: (String? selectedChampionId) {
                    context.read<AuthformBloc>().add(
                        UserFormFieldUpdatedEvent(championId: selectedChampionId));
                  },
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
                          final AppUser updatedUser = AppUser(
                            id: state.id ?? user.id,
                            name: state.name ?? user.name,
                            email: state.email ?? user.email,
                            rank: state.rank ?? user.rank,
                            score: state.score ?? user.score,
                            jokerSum: state.jokerSum ?? user.jokerSum,
                            championId: state.championId ?? user.championId,
                            sixer: state.sixer ?? user.sixer,
                          );
                          context.read<AuthformBloc>().add(UpdateUserEvent(
                              user: updatedUser, currentUser: user));
                        }
                      },
                    ),
                    const SizedBox(width: 8),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
