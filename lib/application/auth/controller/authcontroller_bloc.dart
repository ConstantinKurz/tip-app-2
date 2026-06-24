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

  AuthControllerBloc({required this.authRepository, required this.authBloc})
      : super(AuthControllerInitial()) {
    // Auto-Update bei Auth-Änderungen
    _authBlocSub = authBloc.stream.listen((authState) {
      if (authState is AuthStateAuthenticated) {
        _cachedSignedInUserId = null; // Reset bei Auth-Änderung
        add(AuthAllEvent());
      }
    });

    on<AuthAllEvent>((event, emit) async {
      // ✅ Verhindere mehrfaches Subscriben
      if (_isStreamActive && state is AuthControllerLoaded) {
        debugPrint(
            '⏭️ [AuthControllerBloc] AuthAllEvent SKIPPED: Stream already active');
        return;
      }
      _isStreamActive = true;
      emit(AuthControllerLoading());
      await _usersStreamSub?.cancel();
      _usersStreamSub = authRepository.watchAllUsers().listen((failureOrUsers) {
        add(AuthUpdatedEvent(failureOrUsers: failureOrUsers));
      }, onError: (error) {});
    });

    on<AuthUpdatedEvent>((event, emit) async {
      // ✅ Extrahiere Daten aus fold() BEVOR async Operationen
      AuthFailure? failure;
      List<AppUser>? users;

      event.failureOrUsers.fold(
        (f) => failure = f,
        (u) => users = u,
      );

      if (failure != null) {
        emit(AuthControllerFailure(authFailure: failure!));
        return;
      }

      if (users == null) return;

      final newScoreSum = users!.fold(0, (sum, u) => sum + u.score);

      // ✅ Bei Debouncing: Nur Event triggern, nicht emittieren
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

      // Prüfe ob sich Scores geändert haben → Debouncing starten
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

      // Keine Score-Änderung → sofort emittieren
      _lastTotalScoreSum = newScoreSum;
      final signedInUser = await _getSignedInUser(users!);
      emit(AuthControllerLoaded(
        users: users!,
        signedInUser: signedInUser,
      ));
    });

    // ✅ Handler für debounced Update - nur HIER wird signedInUser geladen
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
    return super.close();
  }
}
