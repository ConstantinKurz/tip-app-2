import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:meta/meta.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';

part 'signupform_event.dart';
part 'signupform_state.dart';

class SignupformBloc extends Bloc<SignupformEvent, SignupformState> {
  final AuthRepository authRepository;

  SignupformBloc({required this.authRepository})
      : super(SignupformState(
          isSubmitting: false,
          showValidationMessages: false,
          authFailureOrSuccessOption: none(),
        )) {
    on<RegisterWithEmailAndPasswordPressed>(_onRegisterPressed);
    on<SignInWithEmailAndPasswordPressed>(_onSignInPressed);
  }

  Future<void> _onRegisterPressed(
    RegisterWithEmailAndPasswordPressed event,
    Emitter<SignupformState> emit,
  ) async {
    if (_isMissingCredentials(event.email, event.password)) {
      emit(state.copyWith(
        isSubmitting: false,
        showValidationMessages: true,
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    final failureOrSuccess =
        await authRepository.registerWithEmailAndPassword(
      email: event.email!,
      password: event.password!,
    );

    emit(state.copyWith(
      isSubmitting: false,
      authFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
  }

  Future<void> _onSignInPressed(
    SignInWithEmailAndPasswordPressed event,
    Emitter<SignupformState> emit,
  ) async {
    if (_isMissingCredentials(event.email, event.password)) {
      emit(state.copyWith(
        isSubmitting: false,
        showValidationMessages: true,
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, showValidationMessages: false));

    final failureOrSuccess =
        await authRepository.signInWithEmailAndPassword(
      email: event.email!,
      password: event.password!,
    );

    emit(state.copyWith(
      isSubmitting: false,
      authFailureOrSuccessOption: optionOf(failureOrSuccess),
    ));
  }

  bool _isMissingCredentials(String? email, String? password) {
    return email == null || password == null;
  }
}
