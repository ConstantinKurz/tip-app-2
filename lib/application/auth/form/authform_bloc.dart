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
    on<CreateUserEvent>(_onCreateUser);
    on<UserFormFieldUpdatedEvent>(_onUserFormFieldUpdated);
    on<UpdateUserEvent>(_onUpdateUser);
    on<UpdateUserWithPasswordEvent>(_onUpdateUserWithPassword);
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<AuthformState> emit,
  ) async {
    if (event.email == null ||
        event.password == null ||
        event.username == null) {
      emit(state.copyWith(showValidationMessages: true));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    final failureOrSuccess = await authRepository.registerWithEmailAndPassword(
      email: event.email!,
      password: event.password!,
      username: event.username!,
      admin: event.admin,
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
      email: event.email ?? state.email,
      admin: event.admin ?? state.admin,
      championId: event.championId ?? state.championId,
      rank: event.rank ?? state.rank,
      score: event.score ?? state.score,
      jokerSum: event.jokerSum ?? state.jokerSum,
      sixer: event.sixer ?? state.sixer,
    ));
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<AuthformState> emit,
  ) async {
    print('═══════════════════════════════════════════════════════════');
    print('📝 [AuthformBloc] _onUpdateUser called');
    print('   event.user: ${event.user?.name} (${event.user?.id})');
    print(
        '   event.currentUser: ${event.currentUser?.name} (${event.currentUser?.id})');
    print('   event.user.email: ${event.user?.email}');
    print('   event.currentUser.email: ${event.currentUser?.email}');
    print('═══════════════════════════════════════════════════════════');

    if (event.user == null) {
      print(
          '⚠️ [AuthformBloc] event.user is null, showing validation messages');
      emit(state.copyWith(showValidationMessages: true, isSubmitting: false));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    // Update user data in Firestore (email change not allowed for other users)
    final failureOrSuccess = await authRepository.updateUser(user: event.user!);

    emit(state.copyWith(
      isSubmitting: false,
      authFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
  }

  Future<void> _onUpdateUserWithPassword(
    UpdateUserWithPasswordEvent event,
    Emitter<AuthformState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    // Check if email changed
    final emailChanged = event.user.email != event.currentUser.email;

    // If email changed, require password and update email
    if (emailChanged) {
      if (event.currentPassword == null || event.currentPassword!.isEmpty) {
        emit(state.copyWith(
          isSubmitting: false,
          authFailureOrSuccessOption: optionOf(left(InvalidCredential(
              message: 'Passwort erforderlich um E-Mail zu ändern'))),
        ));
        return;
      }

      final emailResult = await authRepository.updateOwnEmail(
        newEmail: event.user.email,
        currentPassword: event.currentPassword!,
      );

      if (emailResult.isLeft()) {
        emit(state.copyWith(
          isSubmitting: false,
          authFailureOrSuccessOption: optionOf(emailResult),
        ));
        return;
      }
    }

    // Update password if provided
    if (event.currentPassword != null && event.newPassword != null) {
      final passwordResult = await authRepository.updatePassword(
        currentPassword: event.currentPassword!,
        newPassword: event.newPassword!,
      );

      if (passwordResult.isLeft()) {
        emit(state.copyWith(
          isSubmitting: false,
          authFailureOrSuccessOption: optionOf(passwordResult),
        ));
        return;
      }
    }

    // Update user data in Firestore
    final userResult = await authRepository.updateUser(user: event.user);

    emit(state.copyWith(
      isSubmitting: false,
      authFailureOrSuccessOption: optionOf(userResult),
    ));
  }
}
