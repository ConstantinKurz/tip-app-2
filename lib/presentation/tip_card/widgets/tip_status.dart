import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';

class TipStatus extends StatelessWidget {
  const TipStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TipFormBloc, TipFormState>(
      buildWhen: (previous, current) {
        return previous.tipHome != current.tipHome ||
            previous.tipGuest != current.tipGuest ||
            previous.isSubmitting != current.isSubmitting ||
            previous.isLoading != current.isLoading ||
            previous.failureOrSuccessOption != current.failureOrSuccessOption;
      },
      builder: (context, state) {
        Widget content;

        // ✅ Prüfe zuerst ob InCompleteInputFailure vorliegt
        final hasIncompleteError = state.failureOrSuccessOption.fold(
          () => false,
          (either) => either.fold(
            (failure) => failure is InCompleteInputFailure,
            (_) => false,
          ),
        );

        // ✅ Prüfe ob Joker-Error vorliegt
        final hasJokerError = state.failureOrSuccessOption.fold(
          () => false,
          (either) => either.fold(
            (failure) => failure is JokerLimitReachedFailure,
            (_) => false,
          ),
        );

        // ✅ Loading: nur wenn isLoading = true
        if (state.isLoading) {
          content = const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          );
        }
        // Während Submit Loading → Spinner zeigen
        else if (state.isSubmitting) {
          content = const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          );
        }
        // ✅ InCompleteInputFailure hat Priorität (ROT)
        else if (hasIncompleteError || (state.tipGuest == null && state.tipHome == null)) {
          content = const Tooltip(
            message: 'Tipp unvollständig - beide Felder erforderlich',
            child: Icon(
              Icons.error_outline,
              size: 18,
              color: Colors.red,
            ),
          );
        }
        // ✅ Joker-Error (ORANGE)
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
        // Tipp vollständig (GRÜN)
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
        // Fallback: Loading
        else {
          content = const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
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
