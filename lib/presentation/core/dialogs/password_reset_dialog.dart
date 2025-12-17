import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/signupform/signupform_bloc.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/core/dialogs/custom_dialog.dart';
import 'package:flutter_web/constants.dart';

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key});

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? input) {
    const emailRegex =
        r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";

    if (input == null || input.isEmpty) {
      return "Bitte gebe eine E-Mail ein";
    } else if (!RegExp(emailRegex).hasMatch(input)) {
      return "Keine gültige E-Mail";
    }
    return null;
  }

  String _mapResetFailure(AuthFailure failure) {
    if (failure is UserNotFoundFailure) {
      return "Keine Benutzer mit dieser E-Mail gefunden";
    } else if (failure is InvalidEmailFailure) {
      return "Ungültige E-Mail-Adresse";
    }
    return "Unbekannter Fehler";
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<SignupformBloc, SignupformState>(
      listener: (context, state) {
        state.resetEmailFailureOrSuccessOption.fold(
          () {},
          (result) => result.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    "Fehler beim Senden der E-Mail: ${_mapResetFailure(failure)}",
                    style: themeData.textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
              );
            },
            (_) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(
                    "E-Mail zum Zurücksetzen wurde gesendet!",
                    style: themeData.textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        );
            },
      builder: (context, state) {
        return Container(
          color: Colors.black.withOpacity(0.8), // Schwarzer Hintergrund
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: screenWidth * 0.3,
                height: screenHeight * 0.4,
                decoration: BoxDecoration(
                  color: themeData.scaffoldBackgroundColor,
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Passwort zurücksetzen",
                            style: themeData.textTheme.headlineSmall,
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text.rich(
                                TextSpan(
                                  style: themeData.textTheme.bodyMedium,
                                  children: [
                                    const TextSpan(
                                      text: "Gebe deine E-Mail-Adresse ein. Du erhältst eine E-Mail zum Zurücksetzen deines Passworts. Schaue in deinen ",
                                    ),
                                    TextSpan(
                                      text: "Spamordner",
                                      style: themeData.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(text: "."),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailController,
                                cursorColor: Theme.of(context).colorScheme.onPrimary,
                                style: Theme.of(context).textTheme.bodyLarge,
                                decoration: const InputDecoration(
                                  labelText: "E-Mail",
                                  prefixIcon: Icon(Icons.email),
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 20),
                              CustomButton(
                                width: screenWidth*.1,
                                backgroundColor: themeData.colorScheme.primary,
                                hoverColor: primaryDark,
                                borderColor: primaryDark,
                                buttonText: state.sendingResetEmail ? "Sende..." : "E-Mail senden",
                                callback: state.sendingResetEmail ? () {} : () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    context.read<SignupformBloc>().add(
                                      SendPasswordResetEvent(email: _emailController.text.trim()),
                                    );
                                  }
                                },
                              ),
                              if (state.sendingResetEmail)
                                Center(
                                  child: CircularProgressIndicator(
                                    color: themeData.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}