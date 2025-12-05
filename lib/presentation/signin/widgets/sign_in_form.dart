import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/application/signupform/signupform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/core/dialogs/password_reset_dialog.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _passwordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? validateEmail(String? input) {
    const emailRegex =
        r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";

    if (input == null || input.isEmpty) {
      return "Bitte gebe eine E-Mail ein";
    } else if (!RegExp(emailRegex).hasMatch(input)) {
      return "Keine gültige E-Mail";
    }
    return null;
  }

  String? validatePassword(String? input) {
    if (input == null || input.isEmpty) {
      return "Bitte gebe ein Passwort ein";
    } else if (input.length < 6) {
      return "Passwort muss mindestens 6 Zeichen lang sein";
    }
    return null;
  }

  String mapFailureMessage(AuthFailure failure) {
    switch (failure.runtimeType) {
      case InvalidEmailAndPasswordCombinationFailure:
        return "Falsche E-Mail oder Passwort";
      default:
        return "Ein unerwarteter Fehler ist aufgetreten";
    }
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SignupformBloc>(),
        child: const PasswordResetDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveWrapper.of(context).isLargerThan(TABLET);
    final hDesktopPadding = isDesktop ? screenWidth * 0.3 : 20.0;

    return BlocConsumer<SignupformBloc, SignupformState>(
      listenWhen: (p, c) => p.authFailureOrSuccessOption != c.authFailureOrSuccessOption,
      listener: (context, state) {
        state.authFailureOrSuccessOption.fold(
          () {},
          (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    mapFailureMessage(failure),
                    style: themeData.textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
              );
            },
            (_) {
              context.read<AuthBloc>().add(AuthCheckRequestedEvent());
            },
          ),
        );
      },
      builder: (context, state) {
        return Form(
          autovalidateMode: state.showValidationMessages
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          key: formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: hDesktopPadding),
            children: [
              const SizedBox(height: 80),
              Text(
                "Willkommen",
                style: themeData.textTheme.headlineLarge!.copyWith(
                  fontSize: 50,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),
              Text("Bitte melde Dich sich an", style: themeData.textTheme.bodySmall),
              const SizedBox(height: 80),

              TextFormField(
                controller: emailController,
                cursorColor: Theme.of(context).colorScheme.onPrimary,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: passwordController,
                cursorColor: Theme.of(context).colorScheme.onPrimary,
                style: Theme.of(context).textTheme.bodyLarge,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: "Passwort",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                validator: validatePassword,
                onFieldSubmitted: (_) {
                  if (formKey.currentState!.validate()) {
                    context.read<SignupformBloc>().add(
                      SignInWithEmailAndPasswordPressed(
                        email: emailController.text.trim(),
                        password: passwordController.text,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),

              // Passwort vergessen Link - rechts unter dem Passwort-Feld
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showPasswordResetDialog,
                  child: Text(
                    "Passwort vergessen?",
                    style: themeData.textTheme.bodySmall?.copyWith(
                      color: primaryDark,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.center,
                child: CustomButton(
                  width: screenWidth * 0.1,
                  hoverColor: primaryDark,
                  borderColor: primaryDark,
                  backgroundColor: themeData.scaffoldBackgroundColor,
                  buttonText: state.isSubmitting ? "Wird angemeldet..." : "Anmelden",
                  callback: state.isSubmitting
                      ? () {}
                      : () {
                          if (formKey.currentState!.validate()) {
                            context.read<SignupformBloc>().add(
                              SignInWithEmailAndPasswordPressed(
                                email: emailController.text.trim(),
                                password: passwordController.text,
                              ),
                            );
                          } else {
                            context.read<SignupformBloc>().add(
                              SignInWithEmailAndPasswordPressed(
                                email: null,
                                password: null,
                              ),
                            );
                          }
                        },
                ),
              ),
              const SizedBox(height: 20),

              if (state.isSubmitting)
                Center(
                  child: CircularProgressIndicator(
                    color: themeData.colorScheme.onPrimaryContainer,
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
