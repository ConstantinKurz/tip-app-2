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
  StreamSubscription<Either<TipFailure, Map<String, List<Tip>>>>? _tipStreamSub;

  TipControllerBloc({
    required this.tipRepository,
    required this.validateJokerUseCase,
  }) : super(TipControllerInitial()) {
    on<TipAllEvent>(_onTipAllEvent);
    on<TipUpdatedEvent>(_onTipUpdatedEvent);
    on<TipUpdateStatisticsEvent>(_onUpdateStatistics);
  }

  Future<void> _onTipAllEvent(
    TipAllEvent event,
    Emitter<TipControllerState> emit,
  ) async {
    emit(TipControllerLoading());

    // Vorherigen Stream schließen
    await _tipStreamSub?.cancel();

    _tipStreamSub = tipRepository.watchAll().listen(
      (failureOrTip) => add(TipUpdatedEvent(failureOrTip: failureOrTip)),
      onError: (_) {
        emit(TipControllerFailure(tipFailure: UnexpectedFailure()));
      },
    );
  }

  void _onUserTipEvent(
    UserTipEvent event,
    Emitter<TipControllerState> emit,
  ) {
    emit(TipControllerLoading());
  }

  void _onTipUpdatedEvent(
    TipUpdatedEvent event,
    Emitter<TipControllerState> emit,
  ) async {
    event.failureOrTip.fold(
      (failure) => emit(TipControllerFailure(tipFailure: failure)),
      (tips) async {
        final currentState = state;
        Map<int, MatchDayStatistics> currentStats = {};

        if (currentState is TipControllerLoaded) {
          currentStats = Map.from(currentState.matchDayStatistics);
        }

        emit(TipControllerLoaded(
          tips: tips,
          matchDayStatistics: currentStats,
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
            // ✅ Aktualisiere ALLE Stats für den aktuellen matchDay
            updatedStats[matchDayInPhase] = stats;
          } else {
            // ✅ Für andere matchDays in der Phase: nur jokersUsed aktualisieren
            final existingStat = updatedStats[matchDayInPhase];
            if (existingStat != null) {
              updatedStats[matchDayInPhase] = existingStat.copyWith(
                jokersUsed: stats.jokersUsed,
                jokersAvailable: stats.jokersAvailable, // Auch maxJokers übernehmen
              );
            } else {
              // Falls noch keine Stats vorhanden, erstelle neue
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
