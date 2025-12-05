part of 'signupform_bloc.dart';

class SignupformState {
  final bool isSubmitting;
  final bool sendingResetEmail; // Für Loading-State
  final bool showValidationMessages;
  final Option<Either<AuthFailure, Unit>> authFailureOrSuccessOption;
  final Option<Either<AuthFailure, Unit>> resetEmailFailureOrSuccessOption; // Für Reset-Email

  const SignupformState({
    required this.isSubmitting,
    required this.sendingResetEmail,
    required this.showValidationMessages,
    required this.authFailureOrSuccessOption,
    required this.resetEmailFailureOrSuccessOption,
  });

  SignupformState copyWith({
    bool? isSubmitting,
    bool? sendingResetEmail,
    bool? showValidationMessages,
    Option<Either<AuthFailure, Unit>>? authFailureOrSuccessOption,
    Option<Either<AuthFailure, Unit>>? resetEmailFailureOrSuccessOption,
  }) {
    return SignupformState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      sendingResetEmail: sendingResetEmail ?? this.sendingResetEmail,
      showValidationMessages: showValidationMessages ?? this.showValidationMessages,
      authFailureOrSuccessOption: authFailureOrSuccessOption ?? this.authFailureOrSuccessOption,
      resetEmailFailureOrSuccessOption: resetEmailFailureOrSuccessOption ?? this.resetEmailFailureOrSuccessOption,
    );
  }
}
