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

  AuthControllerBloc({required this.authRepository})
      : super(AuthControllerInitial()) {
    on<AuthAllEvent>((event, emit) async {
      emit(AuthControllerLoading());
      await _usersStreamSub?.cancel();
      _usersStreamSub = authRepository.watchAllUsers().listen((failureOrUsers) {
        print("Stream received value (user)!");
        add(AuthUpdatedEvent(failureOrUsers: failureOrUsers));
      }, onError: (error) {
        print(
            '!!! Firestore stream error detected in AuthControllerBloc: $error');
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

    //   on<AuthUpdatedEvent>((event, emit) {
    //     print(event.failureOrUsers);
    //     print("User received!");
    //     event.failureOrUsers.fold(
    //       (failure) {
    //         print("UsersUpdatedEvent contained Failure: $failure");
    //         emit(AuthControllerFailure(authFailure: failure));
    //       },
    //       (users) {
    //         print(
    //             "UsersUpdatedEvent contained Success with ${users.length} matches");
    //         emit(AuthControllerLoaded(users: users));
    //       },
    //     );
    //   });
    // }

    @override
    Future<void> close() {
      _usersStreamSub?.cancel();
      return super.close();
    }
  }
}
