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
  StreamSubscription<Either<TipFailure, List<Tip>>>? _userTipStreamSub;
  TipControllerBloc({
    required this.tipRepository,
  }) : super(TipControllerInitial()) {
    on<TipAllEvent>((event, emit) async {
      emit(TipControllerLoading());
      // close old subs
      await _tipStreamSub?.cancel();
      _tipStreamSub = tipRepository.watchAll().listen(
          (failureOrTip) => add(TipUpdatedEvent(failureOrTip: failureOrTip)));
    });

    on<UserTipEvent>((event, emit) async {
      emit(TipControllerLoading());

    });

    on<TipUpdatedEvent>((event, emit) {
      event.failureOrTip.fold(
          (failures) => emit(TipControllerFailure(tipFailure: failures)),
          (tips) => emit(TipControllerSuccess(tips: tips)));
    });

    @override
    Future<void> close() async {
      await _tipStreamSub?.cancel();
      return super.close();
    }
  }
}
