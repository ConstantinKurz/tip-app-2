import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';

part 'authform_event.dart';
part 'authform_state.dart';

class AuthformBloc extends Bloc<AuthFormEvent, AuthformState> {
  final AuthRepository authRepository;
  AuthformBloc({required this.authRepository}) : super(AuthFormIntialState()) {
    on<CreateUserEvent>((event, emit) async {
      if (event.email == null || event.password == null) {
        emit(state.copyWith(showValidationMessages: true));
      } else {
        emit(state.copyWith(isSubmitting: true));
        final failureOrSuccess =
            await authRepository.registerWithEmailAndPassword(
                email: event.email!,
                password: event.password!,
                username: event.username);
        emit(state.copyWith(
            isSubmitting: false,
            authFailureOrSuccessOption: optionOf(failureOrSuccess)));
      }
    });

    on<UserFormFieldUpdatedEvent>((event, emit) {
      emit(state.copyWith(
        username: event.username ?? state.username,
        championId: event.championId ?? state.championId,
        email: event.email ?? state.email,
        rank: event.rank ?? state.rank,
        score: event.score ?? state.score,
        jokerSum: event.jokerSum ?? state.jokerSum,
      ));
    });

    on<UpdateUserEvent>((event, emit) async {
      if (event.user != null) {
        emit(state.copyWith(isSubmitting: true, showValidationMessages: false));
        final failureOrSuccess =
            await authRepository.updateUser(user: event.user!);
        print('Update Failure or Success: $failureOrSuccess');
        print("Formupdate event state ${state.copyWith(
          isSubmitting: false,
          authFailureOrSuccessOption: optionOf(failureOrSuccess),
        )}");
        emit(state.copyWith(
          isSubmitting: false,
          authFailureOrSuccessOption: optionOf(failureOrSuccess),
        ));
      } else {
        emit(state.copyWith(isSubmitting: false, showValidationMessages: true));
      }
    });
  }
}
