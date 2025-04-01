import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

class TipForm extends StatelessWidget {
  const TipForm({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final isDesktop = ResponsiveWrapper.of(context).isLargerThan(TABLET);
    final screenWidth = MediaQuery.of(context).size.width;
    final hDesktopPadding = isDesktop ? screenWidth * 0.3 : 20.0;
    bool _isJokerSelected = false;

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    late String _tipHome;
    late String _tipGuest;
    
    return Form(
        // autovalidateMode: state.showValidationMessages
        //     ? AutovalidateMode.always
        //     : AutovalidateMode.disabled,
        key: formKey,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: hDesktopPadding),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 100,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Tipp für Team 1',
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const Text(":"),
              const SizedBox(width: 20),
              const SizedBox(
                width: 100,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Tipp für Team 2',
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const Text("Joker"),
              Checkbox(
                value: _isJokerSelected,
                onChanged: (bool? value) {
                  _isJokerSelected = value ?? false;
                },
              ),
            ],
          ),
        ));
  }
}
