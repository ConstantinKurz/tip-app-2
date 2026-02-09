import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match_day_statistics.dart';
import 'package:flutter_web/domain/entities/match_phase.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/usecases/validate_joker_usage_update_stat_usecase.dart';
import 'package:meta/meta.dart';

part 'tipscontroller_event.dart';
part 'tipscontroller_state.dart';

class TipControllerBloc extends Bloc<TipControllerEvent, TipControllerState> {
  final TipRepository tipRepository;
  final ValidateJokerUsageUpdateStatUseCase validateJokerUseCase;

  StreamSubscription<Either<TipFailure, dynamic>>? _tipStreamSub; // ✅ GEÄNDERT

  TipControllerBloc({
    required this.tipRepository,
    required this.validateJokerUseCase,
  }) : super(TipControllerInitial()) {
    on<TipLoadForUserEvent>(_onLoadForUser); // ✅ NEU
    on<TipAllEvent>(_onTipAllEvent); // ✅ BEHALTEN
    on<TipUpdatedEvent>(_onTipUpdatedEvent); // ✅ NEU
    on<TipUpdateStatisticsEvent>(_onUpdateStatistics);
  }

  // ✅ NEU: Lädt nur Tips des eingeloggten Users
  Future<void> _onLoadForUser(
    TipLoadForUserEvent event,
    Emitter<TipControllerState> emit,
  ) async {
    emit(TipControllerLoading());
    await _tipStreamSub?.cancel();

    _tipStreamSub = tipRepository
        .watchUserTips(event.userId)
        .listen(
          (tipResult) {
            // ✅ Trigger Event statt direkt emit
            add(TipUpdatedEvent(
              failureOrTip: tipResult,
              userId: event.userId,
            ));
          },
          onError: (_) {
            add(TipUpdatedEvent(
              failureOrTip: left(UnexpectedFailure()),
              userId: event.userId,
            ));
          },
        );
  }

  // ✅ NEU: Verarbeitet Updates aus dem Stream
  void _onTipUpdatedEvent(
    TipUpdatedEvent event,
    Emitter<TipControllerState> emit,
  ) {
    event.failureOrTip.fold(
      (failure) => emit(TipControllerFailure(tipFailure: failure)),
      (tips) {
        final currentState = state;
        Map<int, MatchDayStatistics> currentStats = {};

        if (currentState is TipControllerLoaded) {
          currentStats = Map.from(currentState.matchDayStatistics);
        }

        late Map<String, List<Tip>> tipMap;

        // ✅ Prüfe ob List oder Map
        if (tips is List<Tip>) {
          tipMap = {event.userId ?? '': tips};
        } else {
          tipMap = tips as Map<String, List<Tip>>;
        }

        emit(TipControllerLoaded(
          tips: tipMap,
          matchDayStatistics: currentStats,
        ));
      },
    );
  }

  // ✅ BEHALTEN: Für Admin-Dashboard
  Future<void> _onTipAllEvent(
    TipAllEvent event,
    Emitter<TipControllerState> emit,
  ) async {
    emit(TipControllerLoading());
    await _tipStreamSub?.cancel();

    _tipStreamSub = tipRepository.watchAll().listen(
      (failureOrTips) {
        // ✅ Trigger Event statt direkt emit
        add(TipUpdatedEvent(
          failureOrTip: failureOrTips,
          userId: null,
        ));
      },
      onError: (_) {
        add(TipUpdatedEvent(
          failureOrTip: left(UnexpectedFailure()),
          userId: null,
        ));
      },
    );
  }

  Future<void> _onUpdateStatistics(
    TipUpdateStatisticsEvent event,
    Emitter<TipControllerState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TipControllerLoaded) return;

    final statsResult = await validateJokerUseCase(
      userId: event.userId,
      matchDay: event.matchDay,
    );

    statsResult.fold(
      (_) => null,
      (stats) {
        final updatedStats = Map<int, MatchDayStatistics>.from(
          currentState.matchDayStatistics,
        );
        final phase = MatchPhase.fromMatchDay(event.matchDay);
        final matchDaysInPhase = phase.getMatchDaysForPhase();

        for (final matchDayInPhase in matchDaysInPhase) {
          if (event.matchDay == matchDayInPhase) {
            updatedStats[matchDayInPhase] = stats;
          } else {
            final existingStat = updatedStats[matchDayInPhase];
            if (existingStat != null) {
              updatedStats[matchDayInPhase] = existingStat.copyWith(
                jokersUsed: stats.jokersUsed,
                jokersAvailable: stats.jokersAvailable,
              );
            } else {
              updatedStats[matchDayInPhase] = stats.copyWith(
                matchDay: matchDayInPhase,
              );
            }
          }
        }

        emit(currentState.copyWith(
          matchDayStatistics: updatedStats,
        ));
      },
    );
  }

  @override
  Future<void> close() async {
    await _tipStreamSub?.cancel();
    return super.close();
  }
}
