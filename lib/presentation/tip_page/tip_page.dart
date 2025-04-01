import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/signupform/signupform_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_form.dart';
// class TipPage extends StatelessWidget {
//   static String tipPagePath = "/tip";
//   const TipPage({super.key});


// }

  // //TODO: setze hier controller ein. schaue nach todo controller um tips von allen spieler zu laden.
  // // am besten per stream
  // // @override
  // Widget build(BuildContext context) {
  //   return BlocProvider(create: (context) => sl<TipControllerBloc>()..add(UserTipEvent()));
  // }

// class TipList extends StatelessWidget {
//   const TipList({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final themeData = Theme.of(context);
//     return BlocBuilder<TipBloc, TipState>(
//       builder: (context, state) {
//         if (state is TipsLoading) {
//           return Center(child: CircularProgressIndicator());
//         } else if (state is TipsLoaded) {
//           return ListView.builder(
//             itemCount: state.tips.length,
//             itemBuilder: (context, index) {
//               final tip = state.tips[index];
//               return TipForm(tip: tip);
//             },
//           );
//         } else {
//           return Center(child: Text('Fehler beim Laden der Tipps'));
//         }
//       },
//     );
//   }
// }