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

  /// Debouncing für Ranking-Updates (kurz, nur um Firestore-Event-Bursts zu glätten)
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 800);
  int _lastTotalScoreSum = 0;
  List<AppUser>? _pendingUsers;
  AppUser? _pendingSignedInUser;
  bool _isDebouncing = false;

  AuthControllerBloc({required this.authRepository, required this.authBloc})
      : super(AuthControllerInitial()) {
    // Auto-Update bei Auth-Änderungen
    authBloc.stream.listen((authState) {
      if (authState is AuthStateAuthenticated) {
        add(AuthAllEvent());
      }
    });

    on<AuthAllEvent>((event, emit) async {
      emit(AuthControllerLoading());
      await _usersStreamSub?.cancel();
      _usersStreamSub = authRepository.watchAllUsers().listen((failureOrUsers) {
        add(AuthUpdatedEvent(failureOrUsers: failureOrUsers));
      }, onError: (error) {});
    });

    on<AuthUpdatedEvent>((event, emit) async {
      final signedInOption = await authRepository.getSignedInUser();

      event.failureOrUsers.fold(
        (failure) => emit(AuthControllerFailure(authFailure: failure)),
        (users) {
          final signedInUser = signedInOption.getOrElse(() => users.first);
          final newScoreSum = users.fold(0, (sum, u) => sum + u.score);

          // Prüfe ob sich Scores geändert haben
          if (_lastTotalScoreSum != 0 && newScoreSum != _lastTotalScoreSum) {
            // Score-Änderung erkannt → debounce (sammle Events, emitte erst nach 800ms)
            _pendingUsers = users;
            _pendingSignedInUser = signedInUser;
            _isDebouncing = true;

            // Debounce Timer (neu)starten - KEIN Emit während Debounce
            _debounceTimer?.cancel();
            _debounceTimer = Timer(_debounceDuration, () {
              if (_pendingUsers != null) {
                add(_DebouncedUpdateEvent(
                  users: _pendingUsers!,
                  signedInUser: _pendingSignedInUser,
                ));
              }
            });
          } else if (!_isDebouncing) {
            // Keine Score-Änderung und kein laufender Debounce → sofort emittieren
            _lastTotalScoreSum = newScoreSum;
            emit(AuthControllerLoaded(
              users: users,
              signedInUser: signedInUser,
            ));
          } else {
            // Während Debounce: nur pending aktualisieren, nicht emittieren
            _pendingUsers = users;
            _pendingSignedInUser = signedInUser;
          }
        },
      );
    });

    // Handler für debounced Update - einmaliges Emit nach Debounce
    on<_DebouncedUpdateEvent>((event, emit) {
      _lastTotalScoreSum = event.users.fold(0, (sum, u) => sum + u.score);
      _pendingUsers = null;
      _pendingSignedInUser = null;
      _isDebouncing = false;
      emit(AuthControllerLoaded(
        users: event.users,
        signedInUser: event.signedInUser,
      ));
    });
  }

  @override
  Future<void> close() {
    _usersStreamSub?.cancel();
    _debounceTimer?.cancel();
    return super.close();
  }
}
