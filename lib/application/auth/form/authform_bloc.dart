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

  AuthformBloc({required this.authRepository})
      : super(AuthFormIntialState()) {
    on<CreateUserEvent>(_onCreateUser);
    on<UserFormFieldUpdatedEvent>(_onUserFormFieldUpdated);
    on<UpdateUserEvent>(_onUpdateUser);
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<AuthformState> emit,
  ) async {
    if (event.email == null || event.password == null) {
      emit(state.copyWith(showValidationMessages: true));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    final failureOrSuccess =
        await authRepository.registerWithEmailAndPassword(
      email: event.email!,
      password: event.password!,
      username: event.username,
    );

    emit(state.copyWith(
      isSubmitting: false,
      authFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
  }

  void _onUserFormFieldUpdated(
    UserFormFieldUpdatedEvent event,
    Emitter<AuthformState> emit,
  ) {
    emit(state.copyWith(
      name: event.username ?? state.name,
      championId: event.championId ?? state.championId,
      rank: event.rank ?? state.rank,
      score: event.score ?? state.score,
      jokerSum: event.jokerSum ?? state.jokerSum,
    ));
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<AuthformState> emit,
  ) async {
    if (event.user == null) {
      emit(state.copyWith(showValidationMessages: true, isSubmitting: false));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    final failureOrSuccess = await authRepository.updateUser(user: event.user!);

    emit(state.copyWith(
      isSubmitting: false,
      authFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
  }
}
