import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';

class TipStatus extends StatelessWidget {
  final TipFormState state;

  const TipStatus({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TipFormBloc, TipFormState>(
      buildWhen: (previous, current) {
        return previous.tipHome != current.tipHome ||
            previous.tipGuest != current.tipGuest ||
            previous.isSubmitting != current.isSubmitting;
      },
      builder: (context, state) {
        Widget content;
        // Nur während Submit Loading → Spinner zeigen, nicht beim Initial State
        if (state.isSubmitting) {
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
      },
    );
  }
}