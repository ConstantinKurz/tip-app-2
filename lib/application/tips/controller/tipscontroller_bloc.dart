import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/match_day_statistics.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/usecases/validate_joker_usage_update_stat_usecase.dart';
import 'package:meta/meta.dart';

part 'tipscontroller_event.dart';
part 'tipscontroller_state.dart';

class TipControllerBloc extends Bloc<TipControllerEvent, TipControllerState> {
  final TipRepository tipRepository;
  final MatchRepository matchRepository;
  final ValidateJokerUsageUpdateStatUseCase validateJokerUseCase;

  StreamSubscription<Either<TipFailure, dynamic>>? _tipStreamSub;
  
  // Tracking welche MatchDays gerade geladen werden (verhindert parallele Requests)
  final Set<int> _loadingMatchDays = {};
  
  // ✅ Event Counter für Debugging
  int _eventCount = 0;
  
  // ✅ FIX: Flag verhindert mehrfache Stream-Starts
  bool _isStreamActive = false;
  
  // ✅ NEU: Cache für Matches (verhindert redundante DB-Calls)
  List<CustomMatch>? _cachedMatches;
  
  // ✅ FIX: Track current user to reset stats on user change
  String? _currentUserId;

  TipControllerBloc({
    required this.tipRepository,
    required this.matchRepository,
    required this.validateJokerUseCase,
  }) : super(TipControllerInitial()) {
    on<TipLoadForUserEvent>(_onLoadForUser);
    on<TipAllEvent>(_onTipAllEvent);
    on<TipUpdatedEvent>(_onTipUpdatedEvent);
    on<TipUpdateStatisticsEvent>(_onUpdateStatistics);
    on<TipResetEvent>(_onReset);
  }

  @override
  void onEvent(TipControllerEvent event) {
    _eventCount++;
    print('📨 [TipControllerBloc] EVENT #$_eventCount: ${event.runtimeType}');
    if (event is TipUpdateStatisticsEvent) {
      print('   └─ matchDay: ${event.matchDay}, userId: ${event.userId}, forceRefresh: ${event.forceRefresh}');
    } else if (event is TipLoadForUserEvent) {
      print('   └─ userId: ${event.userId}');
    }
    super.onEvent(event);
  }

  @override
  void onTransition(Transition<TipControllerEvent, TipControllerState> transition) {
    print('🔄 [TipControllerBloc] TRANSITION:');
    print('   Event: ${transition.event.runtimeType}');
    print('   From: ${transition.currentState.runtimeType}');
    print('   To: ${transition.nextState.runtimeType}');
    super.onTransition(transition);
  }

  Future<void> _onLoadForUser(
    TipLoadForUserEvent event,
    Emitter<TipControllerState> emit,
  ) async {
    print('👤 [TipControllerBloc] _onLoadForUser: ${event.userId}');
    
    // ✅ FIX: Reset stats cache und stream flag wenn User wechselt
    if (_currentUserId != event.userId) {
      print('🔄 [TipControllerBloc] User changed: $_currentUserId → ${event.userId}, resetting stats');
      _loadingMatchDays.clear();
      _isStreamActive = false;
    }
    _currentUserId = event.userId;
    
    emit(TipControllerLoading());
    await _tipStreamSub?.cancel();

    _tipStreamSub = tipRepository
        .watchUserTips(event.userId)
        .listen(
          (tipResult) {
            print('📥 [TipControllerBloc] Stream event received for user: ${event.userId}');
            add(TipUpdatedEvent(
              failureOrTip: tipResult,
              userId: event.userId,
            ));
          },
          onError: (_) {
            print('❌ [TipControllerBloc] Stream error for user: ${event.userId}');
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

        // ✅ FIX: Nur Stats beibehalten wenn gleicher User
        if (currentState is TipControllerLoaded && 
            event.userId == _currentUserId) {
          currentStats = Map.from(currentState.matchDayStatistics);
        } else {
          print('🧹 [TipControllerBloc] Clearing stats for new user: ${event.userId}');
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
    // ✅ FIX: Bei User-Wechsel (Admin wechselt) Stats zurücksetzen
    // Admin-Mode: _currentUserId auf null setzen bedeutet "alle User"
    if (_currentUserId != null) {
      print('🔄 [TipControllerBloc] Switching to admin mode, resetting stats');
      _loadingMatchDays.clear();
      _isStreamActive = false;
    }
    _currentUserId = null;
    
    // ✅ FIX: Verhindere Stream-Neustart wenn bereits aktiv
    if (_isStreamActive && state is TipControllerLoaded) {
      print('⏭️  [TipControllerBloc] _onTipAllEvent SKIPPED: Stream already active');
      return;
    }
    
    print('🎯 [TipControllerBloc] _onTipAllEvent: Starting watchAll stream');
    _isStreamActive = true;
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

  // ✅ NEU: Reset Bloc State bei Logout
  Future<void> _onReset(
    TipResetEvent event,
    Emitter<TipControllerState> emit,
  ) async {
    print('🧹 [TipControllerBloc] RESET: Clearing all state');
    await _tipStreamSub?.cancel();
    _tipStreamSub = null;
    _loadingMatchDays.clear();
    _isStreamActive = false;
    _currentUserId = null;
    _cachedMatches = null;
    emit(TipControllerInitial());
  }

  Future<void> _onUpdateStatistics(
    TipUpdateStatisticsEvent event,
    Emitter<TipControllerState> emit,
  ) async {
    final currentState = state;

    print('📊 [TipControllerBloc] _onUpdateStatistics START:');
    print('   matchDay: ${event.matchDay}');
    print('   userId: ${event.userId}');
    print('   forceRefresh: ${event.forceRefresh}');
    print('   currentState: ${currentState.runtimeType}');

    // Prüfe nur diesen einzelnen matchDay, nicht die ganze Phase
    if (!event.forceRefresh && currentState is TipControllerLoaded) {
      final currentStats = currentState.matchDayStatistics;
      if (currentStats.containsKey(event.matchDay)) {
        print('   ⏭️  SKIPPED: Stats already loaded for matchDay ${event.matchDay}');
        return;
      }
    }

    if (_loadingMatchDays.contains(event.matchDay)) {
      print('   ⏭️  SKIPPED: Already loading matchDay ${event.matchDay}');
      return;
    }
    
    _loadingMatchDays.add(event.matchDay);
    print('   ✅ Loading stats for matchDay ${event.matchDay}');

    try {
      // ✅ OPTIMIERT: Matches einmal laden für alle KO-Phasen Calls
      // Gruppenphase braucht keine Matches (nutzt maxTips)
      List<CustomMatch>? preloadedMatches;
      if (event.matchDay >= 4) {
        preloadedMatches = await _getOrLoadMatches();
        print('   📦 Preloaded ${preloadedMatches.length} matches for KO stats');
      }

      // ✅ NEU: Vorrunde (matchDay 1-3) teilen sich das 20-Tipp-Limit
      // Alle drei Tage bekommen die gleichen aggregierten Statistiken
      if (event.matchDay >= 1 && event.matchDay <= 3) {
        final stats1Future = validateJokerUseCase(userId: event.userId, matchDay: 1);
        final stats2Future = validateJokerUseCase(userId: event.userId, matchDay: 2);
        final stats3Future = validateJokerUseCase(userId: event.userId, matchDay: 3);
        final results = await Future.wait([stats1Future, stats2Future, stats3Future]);
        _loadingMatchDays.remove(1);
        _loadingMatchDays.remove(2);
        _loadingMatchDays.remove(3);

        final stats1 = results[0].fold((_) => null, (s) => s);
        final stats2 = results[1].fold((_) => null, (s) => s);
        final stats3 = results[2].fold((_) => null, (s) => s);

        if (stats1 == null && stats2 == null && stats3 == null) return;

        final latestState = state;
        final Map<String, List<Tip>> currentTips = latestState is TipControllerLoaded ? latestState.tips : {};
        final Map<int, MatchDayStatistics> previousStats = latestState is TipControllerLoaded ? latestState.matchDayStatistics : {};
        final updatedStats = Map<int, MatchDayStatistics>.from(previousStats);
        if (stats1 != null) updatedStats[1] = stats1;
        if (stats2 != null) updatedStats[2] = stats2;
        if (stats3 != null) updatedStats[3] = stats3;
        emit(TipControllerLoaded(
          tips: currentTips,
          matchDayStatistics: updatedStats,
        ));
        return;
      }

      // ✅ NEU: KO-Vorrunde (16tel, Achtel, Viertelfinale) parallel laden
      // MatchDays 4, 5, 6 werden zusammen geladen für schnellere Performance
      if (event.matchDay >= 4 && event.matchDay <= 6) {
        final stats4Future = validateJokerUseCase(userId: event.userId, matchDay: 4, preloadedMatches: preloadedMatches);
        final stats5Future = validateJokerUseCase(userId: event.userId, matchDay: 5, preloadedMatches: preloadedMatches);
        final stats6Future = validateJokerUseCase(userId: event.userId, matchDay: 6, preloadedMatches: preloadedMatches);
        final results = await Future.wait([stats4Future, stats5Future, stats6Future]);
        _loadingMatchDays.remove(4);
        _loadingMatchDays.remove(5);
        _loadingMatchDays.remove(6);

        final stats4 = results[0].fold((_) => null, (s) => s);
        final stats5 = results[1].fold((_) => null, (s) => s);
        final stats6 = results[2].fold((_) => null, (s) => s);

        if (stats4 == null && stats5 == null && stats6 == null) return;

        final latestState = state;
        final Map<String, List<Tip>> currentTips = latestState is TipControllerLoaded ? latestState.tips : {};
        final Map<int, MatchDayStatistics> previousStats = latestState is TipControllerLoaded ? latestState.matchDayStatistics : {};
        final updatedStats = Map<int, MatchDayStatistics>.from(previousStats);
        if (stats4 != null) updatedStats[4] = stats4;
        if (stats5 != null) updatedStats[5] = stats5;
        if (stats6 != null) updatedStats[6] = stats6;
        emit(TipControllerLoaded(
          tips: currentTips,
          matchDayStatistics: updatedStats,
        ));
        return;
      }

      // Wenn Halbfinale oder Finale: beide Statistiken parallel laden und setzen
      if (event.matchDay == 7 || event.matchDay == 8) {
        final stats7Future = validateJokerUseCase(userId: event.userId, matchDay: 7, preloadedMatches: preloadedMatches);
        final stats8Future = validateJokerUseCase(userId: event.userId, matchDay: 8, preloadedMatches: preloadedMatches);
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
        preloadedMatches: preloadedMatches,
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

  /// ✅ NEU: Hilfsmethode zum Laden/Cachen von Matches
  /// Vermeidet redundante getAllMatches Calls bei parallelen Stats-Loads
  Future<List<CustomMatch>> _getOrLoadMatches() async {
    if (_cachedMatches != null && _cachedMatches!.isNotEmpty) {
      return _cachedMatches!;
    }
    
    final result = await matchRepository.getAllMatches();
    _cachedMatches = result.fold(
      (_) => <CustomMatch>[],
      (matches) => matches,
    );
    return _cachedMatches!;
  }

  @override
  Future<void> close() async {
    await _tipStreamSub?.cancel();
    _loadingMatchDays.clear();
    return super.close();
  }
}
