import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:meta/meta.dart';

part 'authcontroller_event.dart';
part 'authcontroller_state.dart';

class AuthControllerBloc extends Bloc<AuthControllerEvent, AuthControllerState> {
  final AuthRepository authRepository;
  StreamSubscription<Either<AuthFailure, List<AppUser>>>? _usersStreamSub;


  AuthControllerBloc({required this.authRepository}) : super(AuthControllerInitial()) {
    on<AuthAllEvent>((event, emit) async {
      emit(AuthControllerLoading());
      await _usersStreamSub?.cancel();
      _usersStreamSub = authRepository.watchAllUsers().listen((failureOrUsers) {
        add(AuthUpdatedEvent(failureOrUsers: failureOrUsers));
       });
    });

    on<AuthUpdatedEvent>((event, emit) {
      event.failureOrUsers.fold(
        (failure) => emit(AuthControllerFailure(authFailure: failure)),
        (users) => emit(AuthControllerLoaded(users: users)),
      );
    });
  }
}
