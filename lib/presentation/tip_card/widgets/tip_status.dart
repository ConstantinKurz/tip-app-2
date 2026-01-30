import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';

class TipStatus extends StatelessWidget {
  final TipFormState state;

  const TipStatus({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TipFormBloc, TipFormState>(
      buildWhen: (previous, current) {
        return previous.tipHome != current.tipHome ||
            previous.tipGuest != current.tipGuest ||
            previous.isSubmitting != current.isSubmitting ||
            previous.failureOrSuccessOption != current.failureOrSuccessOption; // ✅ NEU
      },
      builder: (context, state) {
        Widget content;
        
        // ✅ Prüfe zuerst ob Joker-Error vorliegt
        final hasJokerError = state.failureOrSuccessOption.fold(
          () => false,
          (either) => either.fold(
            (failure) => failure is JokerLimitReachedFailure,
            (_) => false,
          ),
        );

        // Während Submit Loading → Spinner zeigen
        if (state.isSubmitting) {
          content = const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          );
        } 
        // ✅ Joker-Error hat Priorität
        else if (hasJokerError) {
          content = const Tooltip(
            message: 'Joker-Limit erreicht',
            child: Icon(
              Icons.block,
              size: 18,
              color: Colors.orange,
            ),
          );
        }
        // Tipp vollständig
        else if (state.tipHome != null && state.tipGuest != null) {
          content = const Tooltip(
            message: 'Tipp vollständig',
            child: Icon(
              Icons.check_circle,
              size: 18,
              color: Colors.green,
            ),
          );
        }
        // Tipp unvollständig
        else {
          content = const Tooltip(
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