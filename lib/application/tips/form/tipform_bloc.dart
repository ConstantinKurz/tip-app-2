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
    on<TipFormInitializedEvent>(_onInitialized);
    on<TipFormFieldUpdatedEvent>(_onFieldUpdated);
  }

  void _onInitialized(
    TipFormInitializedEvent event,
    Emitter<TipFormState> emit,
  ) {
    emit(state.copyWith(
      id: event.tip.id,
      userId: event.tip.userId,
      matchId: event.tip.matchId,
      tipDate: event.tip.tipDate,
      tipHome: event.tip.tipHome,
      tipGuest: event.tip.tipGuest,
      joker: event.tip.joker,
    ));
  }

  Future<void> _onFieldUpdated(
    TipFormFieldUpdatedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));

    final isTipHomeNull = event.tipHome == null;
    final isTipGuestNull = event.tipGuest == null;

    // Wenn beide leer, leeren Tip speichern
    if (isTipHomeNull && isTipGuestNull) {
      final newEmptyTip = Tip.empty(event.userId!).copyWith(
        id: "${event.userId}_${event.matchId}",
        matchId: event.matchId,
        joker: false
      );
      final result = await tipRepository.create(newEmptyTip);

      emit(state.copyWith(
        tipGuest: null,
        tipHome: null,
        joker: false,
        isSubmitting: false,
        failureOrSuccessOption: optionOf(result),
      ));
      return;
    }

    if (isTipHomeNull || isTipGuestNull) {
      emit(state.copyWith(
        isSubmitting: false,
        showValidationMessages: true,
        tipGuest: event.tipGuest,
        tipHome: event.tipHome,
        joker: event.joker,
        failureOrSuccessOption: some(left(InCompleteInputFailure())),
      ));
      return;
    }

    final newTip = Tip.empty(event.userId!).copyWith(
      id: "${event.userId}_${event.matchId}",
      matchId: event.matchId,
      tipHome: event.tipHome,
      tipGuest: event.tipGuest,
      joker: event.joker,
    );
    final result = await tipRepository.create(newTip);

    emit(state.copyWith(
      tipGuest: event.tipGuest,
      tipHome: event.tipHome,
      joker: event.joker,
      isSubmitting: false,
      failureOrSuccessOption: optionOf(result),
    ));
  }}