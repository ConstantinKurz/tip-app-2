import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

part 'authcontroller_event.dart';
part 'authcontroller_state.dart';

class AuthControllerBloc
    extends Bloc<AuthControllerEvent, AuthControllerState> {
  final AuthRepository authRepository;
  final AuthBloc authBloc;
  StreamSubscription<Either<AuthFailure, List<AppUser>>>? _usersStreamSub;

  /// Debouncing für Ranking-Updates
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 800);
  int _lastTotalScoreSum = 0;
  List<AppUser>? _pendingUsers;
  bool _isDebouncing = false;

  /// ✅ Cached signed-in user ID - wird nur einmal pro Session geladen
  String? _cachedSignedInUserId;

  /// ✅ AuthBloc Stream Subscription - muss beim close() canceled werden
  StreamSubscription? _authBlocSub;

  /// ✅ Flag um mehrfaches Subscriben zu verhindern
  bool _isStreamActive = false;

  /// ✅ Debounce Timer für Auth-Events
  Timer? _authEventDebounceTimer;

  /// ✅ Retry-Counter für automatische Wiederholung bei Fehlern
  int _retryCount = 0;
  static const int _maxRetries = 5;
  Timer? _retryTimer;

  AuthControllerBloc({required this.authRepository, required this.authBloc})
      : super(AuthControllerInitial()) {
    debugPrint(
        '🎯 [AuthControllerBloc] CONSTRUCTOR called - listening to AuthBloc');
    debugPrint(
        '🎯 [AuthControllerBloc] Current AuthBloc state: ${authBloc.state.runtimeType}');

    // ═══════════════════════════════════════════════════════════════════════
    // ✅ WICHTIG: ALLE Event-Handler ZUERST registrieren!
    // ═══════════════════════════════════════════════════════════════════════

    on<AuthAllEvent>((event, emit) async {
      debugPrint('🎯 [AuthControllerBloc] AuthAllEvent received');
      if (_isStreamActive) {
        debugPrint(
            '⏭️ [AuthControllerBloc] AuthAllEvent SKIPPED: Stream already active');
        return;
      }
      _isStreamActive = true;
      debugPrint(
          '🎯 [AuthControllerBloc] Emitting AuthControllerLoading, calling watchAllUsers()...');
      emit(AuthControllerLoading());
      await _usersStreamSub?.cancel();
      _usersStreamSub = authRepository.watchAllUsers().listen((failureOrUsers) {
        debugPrint('🎯 [AuthControllerBloc] watchAllUsers() received data');
        add(AuthUpdatedEvent(failureOrUsers: failureOrUsers));
      }, onError: (error) {
        debugPrint('🎯 [AuthControllerBloc] watchAllUsers() onError: $error');
      });
    });

    on<AuthUpdatedEvent>((event, emit) async {
      AuthFailure? failure;
      List<AppUser>? users;

      event.failureOrUsers.fold(
        (f) => failure = f,
        (u) => users = u,
      );

      if (failure != null) {
        if (_retryCount < _maxRetries) {
          _retryCount++;
          debugPrint(
              '🔄 [AuthControllerBloc] Retry $_retryCount/$_maxRetries nach Fehler: $failure');
          _isStreamActive = false;
          _retryTimer?.cancel();
          debugPrint(
              '🧹 [AuthControllerBloc] Calling resetUsersStream() for RETRY');
          authRepository.resetUsersStream();
          _retryTimer = Timer(Duration(seconds: _retryCount * 3), () {
            add(AuthAllEvent());
          });
          return;
        }
        debugPrint(
            '❌ [AuthControllerBloc] Max Retries erreicht, zeige Fehler: $failure');
        emit(AuthControllerFailure(authFailure: failure!));
        return;
      }

      _retryCount = 0;
      if (users == null) return;

      final newScoreSum = users!.fold(0, (sum, u) => sum + u.score);

      if (_isDebouncing) {
        _pendingUsers = users;
        _debounceTimer?.cancel();
        _debounceTimer = Timer(_debounceDuration, () {
          if (_pendingUsers != null) {
            add(_DebouncedUpdateEvent(users: _pendingUsers!));
          }
        });
        return;
      }

      if (_lastTotalScoreSum != 0 && newScoreSum != _lastTotalScoreSum) {
        _pendingUsers = users;
        _isDebouncing = true;
        _debounceTimer?.cancel();
        _debounceTimer = Timer(_debounceDuration, () {
          if (_pendingUsers != null) {
            add(_DebouncedUpdateEvent(users: _pendingUsers!));
          }
        });
        return;
      }

      _lastTotalScoreSum = newScoreSum;
      final signedInUser = await _getSignedInUser(users!);
      emit(AuthControllerLoaded(
        users: users!,
        signedInUser: signedInUser,
      ));
    });

    on<_DebouncedUpdateEvent>((event, emit) async {
      _lastTotalScoreSum = event.users.fold(0, (sum, u) => sum + u.score);
      _pendingUsers = null;
      _isDebouncing = false;

      final signedInUser = await _getSignedInUser(event.users);
      emit(AuthControllerLoaded(
        users: event.users,
        signedInUser: signedInUser,
      ));
    });

    on<_AuthResetEvent>((event, emit) async {
      await _usersStreamSub?.cancel();
      _isStreamActive = false;
      _cachedSignedInUserId = null;
      _lastTotalScoreSum = 0;
      _pendingUsers = null;
      _isDebouncing = false;
      _retryCount = 0;
      _retryTimer?.cancel();
      emit(AuthControllerInitial());
    });

    // ═══════════════════════════════════════════════════════════════════════
    // ✅ JETZT: Stream Listener registrieren (NACH allen Handlern!)
    // ═══════════════════════════════════════════════════════════════════════

    _authBlocSub = authBloc.stream.listen((authState) {
      debugPrint(
          '🎯 [AuthControllerBloc] AuthBloc emitted: ${authState.runtimeType}');
      if (authState is AuthStateAuthenticated) {
        _authEventDebounceTimer?.cancel();
        _authEventDebounceTimer = Timer(const Duration(milliseconds: 100), () {
          debugPrint(
              '🎯 [AuthControllerBloc] AuthStateAuthenticated -> calling AuthAllEvent()');
          _cachedSignedInUserId = null;
          add(AuthAllEvent());
        });
      } else if (authState is AuthStateUnAuthenticated) {
        debugPrint(
            '🎯 [AuthControllerBloc] AuthStateUnAuthenticated -> calling _AuthResetEvent()');
        _authEventDebounceTimer?.cancel();
        add(_AuthResetEvent());
      }
    });

    // ═══════════════════════════════════════════════════════════════════════
    // ✅ ZULETZT: Check current state - if already authenticated
    // ═══════════════════════════════════════════════════════════════════════

    if (authBloc.state is AuthStateAuthenticated) {
      debugPrint(
          '🎯 [AuthControllerBloc] Auth ALREADY authenticated -> starting immediately');
      add(AuthAllEvent());
    }
  }

  /// ✅ Holt den signed-in User mit Caching - nur einmal pro Session laden
  Future<AppUser?> _getSignedInUser(List<AppUser> users) async {
    if (_cachedSignedInUserId == null) {
      final signedInOption = await authRepository.getSignedInUser();
      _cachedSignedInUserId = signedInOption.fold(
        () => null,
        (user) => user.id,
      );
    }

    if (_cachedSignedInUserId == null) {
      return users.isNotEmpty ? users.first : null;
    }

    return users.firstWhere(
      (u) => u.id == _cachedSignedInUserId,
      orElse: () => users.first,
    );
  }

  @override
  Future<void> close() {
    _usersStreamSub?.cancel();
    _authBlocSub?.cancel();
    _debounceTimer?.cancel();
    _authEventDebounceTimer?.cancel();
    _retryTimer?.cancel();
    return super.close();
  }
}
