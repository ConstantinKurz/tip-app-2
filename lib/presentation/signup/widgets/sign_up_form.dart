import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/signupform/signupform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/home_page/home_page.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:routemaster/routemaster.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    late String _email;
    late String _password;

    String? validateEmail(String? input) {
      const emailRegex =
          r"""^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""";

      if (input == null || input.isEmpty) {
        return "please enter email";
      } else if (RegExp(emailRegex).hasMatch(input)) {
        _email = input;
        return null;
      } else {
        return "invalid email format";
      }
    }

    String mapFailureMessage(AuthFailure failure) {
      switch (failure.runtimeType) {
        case ServerFailure:
          return "Something went wrong";
        case EmailAlreadyInUseFailure:
          return "Email already in use";
        case InvalidEmailAndPasswordCombinationFailure:
          return "Invalid email and password combination";
        default:
          return "Something went wrong";
      }
    }

    String? validatePassword(String? input) {
      if (input == null || input.isEmpty) {
        return "please enter password";
      } else if (input.length >= 6) {
        _password = input;
        return null;
      } else {
        return "short password";
      }
    }

    final themeData = Theme.of(context);
    final isDesktop = ResponsiveWrapper.of(context).isLargerThan(TABLET);
    final screenWidth = MediaQuery.of(context).size.width;
    final hDesktopPadding = isDesktop ? screenWidth * 0.3 : 20.0;

    return BlocConsumer<SignupformBloc, SignupformState>(
      listenWhen: (p, c) =>
          p.authFailureOrSuccessOption != c.authFailureOrSuccessOption,
      listener: (context, state) {
        state.authFailureOrSuccessOption.fold(
            () {},
            (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold((failure) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text(
                        mapFailureMessage(failure),
                        style: themeData.textTheme.bodyLarge,
                      )));
                }, (_) {
                  Routemaster.of(context).replace(HomePage.homePagePath);
                }));
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
              const SizedBox(
                height: 80,
              ),
              Text(
                "Welcome",
                style: themeData.textTheme.headlineLarge!.copyWith(
                    fontSize: 50,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4),
              ),
              const SizedBox(
                height: 20,
              ),
              Text("Please register", style: themeData.textTheme.bodySmall),
              const SizedBox(
                height: 80,
              ),
              TextFormField(
                cursorColor: Colors.white,
                decoration: const InputDecoration(labelText: "Email"),
                validator: validateEmail,
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                cursorColor: Colors.white,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: validatePassword,
              ),
              const SizedBox(
                height: 40,
              ),
              CustomButton(
                hoverColor: primaryDark,
                borderColor: primaryDark,
                backgroundColor: themeData.scaffoldBackgroundColor,
                buttonText: "Register",
                callback: () {
                  {
                    if (formKey.currentState!.validate()) {
                      BlocProvider.of<SignupformBloc>(context).add(
                          RegisterWithEmailAndPasswordPressed(
                              email: _email, password: _password));
                    } else {
                      BlocProvider.of<SignupformBloc>(context).add(
                          RegisterWithEmailAndPasswordPressed(
                              email: null, password: null));

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            "invalid input",
                            style: themeData.textTheme.bodyLarge,
                          )));
                    }
                  }
                },
              ),
              if (state.isSubmitting) ...[
                const SizedBox(
                  height: 10,
                ),
                LinearProgressIndicator(
                  color: themeData.colorScheme.secondary,
                )
              ]
            ],
          ),
        );
      },
    );
  }
}
