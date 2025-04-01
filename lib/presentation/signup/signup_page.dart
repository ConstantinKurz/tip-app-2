import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/signupform/signupform_bloc.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/signup/widgets/sign_up_form.dart';

class SignUpPage extends StatelessWidget {
  static String signupPagePath = "/signup";
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => sl<SignupformBloc>(),
        child: const PageTemplate(child: SignUpForm())
      ),
    );
  }
}
