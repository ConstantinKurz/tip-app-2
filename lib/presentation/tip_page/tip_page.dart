import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';

class TipPage extends StatelessWidget {
  TipPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.width;
    final themeData = Theme.of(context);

    return BlocProvider(
      create: (context) => sl<TipControllerBloc>()..add(TipAllEvent()),
      child: Scaffold(body: BlocBuilder<TipControllerBloc, TipControllerState>(
          builder: (context, state) {
        if (state is TipControllerFailure) {
          return Center(child: Text("Tip Failure: ${state.tipFailure}"));
        }
        return PageTemplate(
          child: Placeholder(),
        );
      })),
    );
  }
}
