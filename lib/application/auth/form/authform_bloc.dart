import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';

part 'authform_event.dart';
part 'authform_state.dart';

class AuthformBloc extends Bloc<AuthFormEvent, AuthformState> {
  final AuthRepository authRepository;
  AuthformBloc({required this.authRepository})
      : super(AuthformState(
            isSubmitting: false,
            sendingResetMail: false,
            showValidationMessages: false,
            authFailureOrSuccessOption: none())) {
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
  }
}
