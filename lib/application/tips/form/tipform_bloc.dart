import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/tip.dart';

part 'tipform_event.dart';
part 'tipform_state.dart';

class TipFormBloc extends Bloc<TipFormEvent, TipFormState> {
  final TipRepository tipRepository;
  TipFormBloc({required this.tipRepository}) : super(TipFormInitialState()) {
    on<TipFormFieldUpdatedEvent>((event, emit) async {
      if (event.tipGuest == null || event.tipHome == null) {
        emit(
            state.copyWith(isSubmitting: false, showValidationMessages: false, tipGuest: event.tipGuest, tipHome: event.tipHome));
      } else if ((event.tipGuest == null || event.tipHome == null) &&
          event.joker != null) {
        emit(state.copyWith(isSubmitting: false, showValidationMessages: true));
      } else {
        Tip newTip = Tip.empty(event.userId!).copyWith(
            id: "${event.userId}_${event.matchId}",
            matchId: event.matchId,
            tipHome: event.tipHome,
            tipGuest: event.tipGuest,
            joker: event.joker);
        final failureOrSucces = await tipRepository.create(newTip);

        emit(state.copyWith(
            isSubmitting: false,
            failureOrSuccessOption: optionOf(failureOrSucces)));
      }
    });
  }
}
