import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/core/failures/match_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';

part 'matchescontroller_event.dart';
part 'matchescontroller_state.dart';

class MatchesControllerBloc
    extends Bloc<MatchesControllerEvent, MatchesControllerState> {
  final MatchRepository matchRepository;
  final AuthBloc authBloc;
  StreamSubscription<Either<MatchFailure, List<CustomMatch>>>? _matchStreamSub;
  StreamSubscription? _authBlocSub;
  bool _isStreamActive = false;

  MatchesControllerBloc({required this.matchRepository, required this.authBloc})
      : super(MatchesControllerInitial()) {
    debugPrint(
        '🎮 [MatchesControllerBloc] CONSTRUCTOR - listening to AuthBloc');
    debugPrint('🎮 [MatchesControllerBloc] Current AuthBloc state: ${authBloc.state.runtimeType}');
    
    // ✅ WICHTIG: Event-Handler ZUERST registrieren!
    on<MatchesAllEvent>(_onMatchesAllEvent);
    on<MatchUpdatedEvent>(_onMatchUpdatedEvent);

    // ✅ Automatisch starten wenn Auth ready ist
    _authBlocSub = authBloc.stream.listen((authState) {
      debugPrint(
          '🎮 [MatchesControllerBloc] AuthBloc emitted: ${authState.runtimeType}');
      if (authState is AuthStateAuthenticated && !_isStreamActive) {
        debugPrint(
            '🎮 [MatchesControllerBloc] Auth ready -> starting matches stream');
        add(MatchesAllEvent());
      }
    });
    
    // ✅ Check current state - if already authenticated, start immediately
    // NACH der Handler-Registrierung!
    if (authBloc.state is AuthStateAuthenticated) {
      debugPrint('🎮 [MatchesControllerBloc] Auth ALREADY authenticated -> starting immediately');
      add(MatchesAllEvent());
    }
  }

  Future<void> _onMatchesAllEvent(
    MatchesAllEvent event,
    Emitter<MatchesControllerState> emit,
  ) async {
    if (_isStreamActive) {
      debugPrint(
          '⏭️ [MatchesControllerBloc] MatchesAllEvent SKIPPED: Stream already active');
      return;
    }
    _isStreamActive = true;
    
    // ✅ Reset stream to force fresh Firestore subscription (in case old one got InsufficientPermissions)
    debugPrint('🧹 [MatchesControllerBloc] Resetting matches stream before subscribing...');
    matchRepository.resetMatchesStream();
    
    debugPrint('🎮 [MatchesControllerBloc] Starting watchAllMatches stream');
    emit(MatchesControllerLoading());

    await _matchStreamSub?.cancel();

    _matchStreamSub = matchRepository.watchAllMatches().listen(
      (failureOrMatches) =>
          add(MatchUpdatedEvent(failureOrMatches: failureOrMatches)),
      onError: (_) {
        // Sollte selten vorkommen, da das Repository schon mapFirebaseError nutzt
        emit(MatchesControllerFailure(matchFailure: UnexpectedFailure()));
      },
    );
  }

  void _onMatchUpdatedEvent(
    MatchUpdatedEvent event,
    Emitter<MatchesControllerState> emit,
  ) {
    event.failureOrMatches.fold(
      (failure) => emit(MatchesControllerFailure(matchFailure: failure)),
      (matches) => emit(MatchesControllerLoaded(matches: matches)),
    );
  }

  @override
  Future<void> close() {
    _matchStreamSub?.cancel();
    _authBlocSub?.cancel();
    return super.close();
  }
}
