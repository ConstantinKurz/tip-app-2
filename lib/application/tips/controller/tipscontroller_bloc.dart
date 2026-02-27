import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match_day_statistics.dart';
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

    // Prüfe nur diesen einzelnen matchDay, nicht die ganze Phase
    if (!event.forceRefresh && currentState is TipControllerLoaded) {
      final currentStats = currentState.matchDayStatistics;
      if (currentStats.containsKey(event.matchDay)) return;
    }

    if (_loadingMatchDays.contains(event.matchDay)) {
      return;
    }
    _loadingMatchDays.add(event.matchDay);

    try {
      // Wenn Halbfinale oder Finale: beide Statistiken parallel laden und setzen
      if (event.matchDay == 7 || event.matchDay == 8) {
        final stats7Future = validateJokerUseCase(userId: event.userId, matchDay: 7);
        final stats8Future = validateJokerUseCase(userId: event.userId, matchDay: 8);
        final results = await Future.wait([stats7Future, stats8Future]);
        _loadingMatchDays.remove(7);
        _loadingMatchDays.remove(8);

        final stats7 = results[0].fold((_) => null, (s) => s);
        final stats8 = results[1].fold((_) => null, (s) => s);

        if (stats7 == null && stats8 == null) return;

        final latestState = state;
        final Map<String, List<Tip>> currentTips = latestState is TipControllerLoaded ? latestState.tips : {};
        final Map<int, MatchDayStatistics> previousStats = latestState is TipControllerLoaded ? latestState.matchDayStatistics : {};
        final updatedStats = Map<int, MatchDayStatistics>.from(previousStats);
        if (stats7 != null) updatedStats[7] = stats7;
        if (stats8 != null) updatedStats[8] = stats8;
        emit(TipControllerLoaded(
          tips: currentTips,
          matchDayStatistics: updatedStats,
        ));
        return;
      }

      // Sonst wie gehabt für einzelne Tage
      final statsResult = await validateJokerUseCase(
        userId: event.userId,
        matchDay: event.matchDay,
      );
      _loadingMatchDays.remove(event.matchDay);
      final MatchDayStatistics? stats = statsResult.fold((failure) => null, (s) => s);
      if (stats == null) return;
      final latestState = state;
      final Map<String, List<Tip>> currentTips = latestState is TipControllerLoaded ? latestState.tips : {};
      final Map<int, MatchDayStatistics> previousStats = latestState is TipControllerLoaded ? latestState.matchDayStatistics : {};
      final updatedStats = Map<int, MatchDayStatistics>.from(previousStats);
      updatedStats[event.matchDay] = stats;
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
