import 'package:flutter/material.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';

class TipStatus extends StatelessWidget {
  final TipFormState state;

  const TipStatus({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    Widget content;
    if (state is TipFormInitialState || state.isSubmitting) {
      content = const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    } else {
      content = (state.tipHome != null && state.tipGuest != null)
          ? const Tooltip(
              message: 'Tipp vollständig',
              child: Icon(
                Icons.check_circle,
                size: 18,
                color: Colors.green,
              ),
            )
          : const Tooltip(
              message: 'Tipp unvollständig',
              child: Icon(
                Icons.error_outline,
                size: 18,
                color: Colors.red,
              ),
            );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: content,
    );
  }
}