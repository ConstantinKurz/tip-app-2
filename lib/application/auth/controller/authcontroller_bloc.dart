import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:meta/meta.dart';

part 'authcontroller_event.dart';
part 'authcontroller_state.dart';

class AuthControllerBloc
    extends Bloc<AuthControllerEvent, AuthControllerState> {
  final AuthRepository authRepository;

  StreamSubscription<Either<AuthFailure, List<AppUser>>>? _usersStreamSub;

  AppUser? _cachedSignedInUser;
  String? _cachedSignedInUserId;
  bool _isWatchingUsers = false;

  AuthControllerBloc({
    required this.authRepository,
  }) : super(AuthControllerInitial()) {
    on<AuthAllEvent>((event, emit) async {
      if (_isWatchingUsers) {
        return;
      }

      emit(AuthControllerLoading());

      final signedInOption = await authRepository.getSignedInUser();

      signedInOption.fold(
        () {
          _cachedSignedInUser = null;
          _cachedSignedInUserId = null;
        },
        (user) {
          _cachedSignedInUser = user;
          _cachedSignedInUserId = user.id;
        },
      );

      await _usersStreamSub?.cancel();

      _isWatchingUsers = true;

      _usersStreamSub = authRepository.watchAllUsers().listen(
        (failureOrUsers) {
          add(AuthUpdatedEvent(failureOrUsers: failureOrUsers));
        },
        onError: (error) {},
      );
    });

    on<AuthUpdatedEvent>((event, emit) async {
      event.failureOrUsers.fold(
        (failure) {
          emit(AuthControllerFailure(authFailure: failure));
        },
        (users) {
          AppUser? signedInUser;

          if (_cachedSignedInUserId != null) {
            for (final user in users) {
              if (user.id == _cachedSignedInUserId) {
                signedInUser = user;
                break;
              }
            }
          }

          signedInUser ??= _cachedSignedInUser;

          if (signedInUser == null && users.isNotEmpty) {
            signedInUser = users.first;
          }

          _cachedSignedInUser = signedInUser;

          emit(
            AuthControllerLoaded(
              users: users,
              signedInUser: signedInUser,
            ),
          );
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await _usersStreamSub?.cancel();
    return super.close();
  }
}
