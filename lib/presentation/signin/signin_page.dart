import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/signupform/signupform_bloc.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/signin/widgets/sign_in_form.dart';

class SignInPage extends StatelessWidget {
  static String signinPagePath = "/signin";
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => sl<SignupformBloc>(),
        child: const PageTemplate(child: SignInForm())
      ),
    );
  }
}
