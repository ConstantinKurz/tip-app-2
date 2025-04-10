import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Ensure this path is correct
import 'package:flutter_web/application/auth/form/authform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';

class CreateUserForm extends StatefulWidget {
  const CreateUserForm({Key? key}) : super(key: key);

  @override
  _CreateUserFormState createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<CreateUserForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late String _username;
  late String _email;
  late String _password;

  String? validateString(String? input) {
    if (input == null || input.isEmpty) {
      return "Bitte geben Sie einen Wert ein";
    } else {
      return null;
    }
  }

  String? validateEmail(String? input) {
    const emailRegex =
        r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";

    if (input == null || input.isEmpty) {
      return "Gebe eine Mail ein";
    } else if (RegExp(emailRegex).hasMatch(input)) {
      _email = input;
      return null;
    } else {
      return "Keine email";
    }
  }

  String? validatePassword(String? input) {
    if (input == null || input.isEmpty) {
      return "Gebe ein PWD ein";
    } else if (input.length >= 6) {
      _password = input;
      return null;
    } else {
      return "Zu kurz";
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return BlocConsumer<AuthformBloc, AuthformState>(
      // Use the correct Bloc
      listenWhen: (p, c) =>
          p.authFailureOrSuccessOption != c.authFailureOrSuccessOption,
      listener: (context, state) {
        state.authFailureOrSuccessOption!.fold(
            () {},
            (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold((failure) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text(
                        "Fehler beim Erstellen des Benutzers",
                        style: themeData.textTheme.bodyLarge,
                      )));
                }, (_) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                        "Benutzer erfolgreich erstellt!",
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
                decoration: const InputDecoration(labelText: 'Benutzername'),
                validator: validateString,
                onChanged: (value) => _username = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                validator: validateEmail,
                onChanged: (value) => _email = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Passwort'),
                obscureText: true, // Hide password
                validator: validatePassword,
                onChanged: (value) => _password = value,
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                CustomButton(
                  buttonText: 'Speichern',
                  backgroundColor: themeData.colorScheme.primaryContainer,
                  borderColor: primaryDark,
                  hoverColor: primaryDark,
                  callback: () {
                    if (formKey.currentState!.validate()) {
                      BlocProvider.of<AuthformBloc>(context).add(
                        CreateUserEvent(
                          username: _username,
                          email: _email,
                          password: _password,
                        ),
                      );
                    } else {
                      BlocProvider.of<AuthformBloc>(context).add(
                        CreateUserEvent(
                            username: null, email: null, password: null),
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
              ]),
            ],
          ),
        );
      },
    );
  }
}
