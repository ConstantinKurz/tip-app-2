import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:meta/meta.dart';

part 'tipscontroller_event.dart';
part 'tipscontroller_state.dart';

class TipControllerBloc extends Bloc<TipControllerEvent, TipControllerState> {
  final TipRepository tipRepository;
  StreamSubscription<Either<TipFailure, Map<String, List<Tip>>>>? _tipStreamSub;

  TipControllerBloc({required this.tipRepository})
      : super(TipControllerInitial()) {
    on<TipAllEvent>(_onTipAllEvent);
    on<UserTipEvent>(_onUserTipEvent);
    on<TipUpdatedEvent>(_onTipUpdatedEvent);
  }

  Future<void> _onTipAllEvent(
    TipAllEvent event,
    Emitter<TipControllerState> emit,
  ) async {
    emit(TipControllerLoading());

    // Vorherigen Stream schließen
    await _tipStreamSub?.cancel();

    _tipStreamSub = tipRepository.watchAll().listen(
      (failureOrTip) =>
          add(TipUpdatedEvent(failureOrTip: failureOrTip)),
      onError: (_) {
        // Sollte selten passieren, da das Repository bereits mapFirebaseError nutzt
        emit(TipControllerFailure(tipFailure: UnexpectedFailure()));
      },
    );
  }

  void _onUserTipEvent(
    UserTipEvent event,
    Emitter<TipControllerState> emit,
  ) {
    emit(TipControllerLoading());
    // Falls später zusätzliche Logik für User-spezifische Streams kommt,
    // kann sie hier ergänzt werden.
  }

  void _onTipUpdatedEvent(
    TipUpdatedEvent event,
    Emitter<TipControllerState> emit,
  ) {
    event.failureOrTip.fold(
      (failure) => emit(TipControllerFailure(tipFailure: failure)),
      (tips) => emit(TipControllerLoaded(tips: tips)),
    );
  }

  @override
  Future<void> close() async {
    await _tipStreamSub?.cancel();
    return super.close();
  }
}
