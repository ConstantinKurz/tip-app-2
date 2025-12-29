import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:meta/meta.dart';

part 'authcontroller_event.dart';
part 'authcontroller_state.dart';

class AuthControllerBloc
    extends Bloc<AuthControllerEvent, AuthControllerState> {
  final AuthRepository authRepository;
  final AuthBloc authBloc;
  StreamSubscription<Either<AuthFailure, List<AppUser>>>? _usersStreamSub;

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
      }, onError: (error) {
      });
    });

    on<AuthUpdatedEvent>((event, emit) async {
      final signedInOption = await authRepository.getSignedInUser();

      event.failureOrUsers.fold(
        (failure) => emit(AuthControllerFailure(authFailure: failure)),
        (users) {
          emit(AuthControllerLoaded(
            users: users,
            signedInUser: signedInOption.getOrElse(() => users.first),
          ));
        },
      );
    });

    @override
    Future<void> close() {
      _usersStreamSub?.cancel();
      return super.close();
    }
  }
}
