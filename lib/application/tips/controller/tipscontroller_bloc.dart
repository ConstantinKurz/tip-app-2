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

  StreamSubscription<Either<TipFailure, dynamic>>? _tipStreamSub;
  
  // Tracking welche MatchDays gerade geladen werden (verhindert parallele Requests)
  final Set<int> _loadingMatchDays = {};

  TipControllerBloc({
    required this.tipRepository,
    required this.validateJokerUseCase,
  }) : super(TipControllerInitial()) {
    on<TipLoadForUserEvent>(_onLoadForUser);
    on<TipAllEvent>(_onTipAllEvent);
    on<TipUpdatedEvent>(_onTipUpdatedEvent);
    on<TipUpdateStatisticsEvent>(_onUpdateStatistics);
  }

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

  Future<void> _onTipAllEvent(
    TipAllEvent event,
    Emitter<TipControllerState> emit,
  ) async {
    emit(TipControllerLoading());
    await _tipStreamSub?.cancel();

    _tipStreamSub = tipRepository.watchAll().listen(
      (failureOrTips) {
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

    final phase = MatchPhase.fromMatchDay(event.matchDay);
    final matchDaysInPhase = phase.getMatchDaysForPhase();

    // Wenn bereits alle Stats für diese Phase existieren UND kein forceRefresh -> nichts tun
    if (!event.forceRefresh && currentState is TipControllerLoaded) {
      final currentStats = currentState.matchDayStatistics;
      final allExist = matchDaysInPhase.every((d) => currentStats.containsKey(d));
      if (allExist) return;
    }

    // Prüfe ob dieser MatchDay bereits geladen wird (verhindert parallele Requests)
    if (_loadingMatchDays.contains(event.matchDay)) {
      return;
    }

    // Markiere als "wird geladen"
    _loadingMatchDays.add(event.matchDay);

    try {
      final statsResult = await validateJokerUseCase(
        userId: event.userId,
        matchDay: event.matchDay,
      );

      _loadingMatchDays.remove(event.matchDay);

      // Extrahiere den Wert aus Either BEVOR wir emit aufrufen
      final MatchDayStatistics? stats = statsResult.fold(
        (failure) => null,
        (s) => s,
      );

      // Wenn Stats null sind (Fehler), abbrechen
      if (stats == null) {
        return;
      }

      // Aktuellen State holen
      final latestState = state;
      
      final Map<String, List<Tip>> currentTips;
      final Map<int, MatchDayStatistics> previousStats;
      
      if (latestState is TipControllerLoaded) {
        currentTips = latestState.tips;
        previousStats = latestState.matchDayStatistics;
      } else {
        currentTips = {};
        previousStats = {};
      }

      // Nochmal prüfen ob inzwischen geladen (nur wenn kein forceRefresh)
      if (!event.forceRefresh) {
        final allExistNow = matchDaysInPhase.every((d) => previousStats.containsKey(d));
        if (allExistNow) {
          return;
        }
      }

      final updatedStats = Map<int, MatchDayStatistics>.from(previousStats);

      for (final matchDayInPhase in matchDaysInPhase) {
        if (event.forceRefresh || !updatedStats.containsKey(matchDayInPhase)) {
          if (event.matchDay == matchDayInPhase) {
            updatedStats[matchDayInPhase] = stats;
          } else {
            updatedStats[matchDayInPhase] = stats.copyWith(
              matchDay: matchDayInPhase,
            );
          }
        }
      }

      // Emit NACH dem fold, nicht innerhalb
      emit(TipControllerLoaded(
        tips: currentTips,
        matchDayStatistics: updatedStats,
      ));
      
    } catch (_) {
      _loadingMatchDays.remove(event.matchDay);
    }
  }

  @override
  Future<void> close() async {
    await _tipStreamSub?.cancel();
    _loadingMatchDays.clear();
    return super.close();
  }
}
