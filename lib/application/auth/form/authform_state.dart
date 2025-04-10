part of 'authform_bloc.dart';

@immutable
class AuthformState {
  final bool isSubmitting;
  final bool sendingResetMail;
  final bool showValidationMessages;
  final Option<Either<AuthFailure, Unit>>? authFailureOrSuccessOption;

  AuthformState(
      {required this.isSubmitting,
      required this.sendingResetMail,
      required this.showValidationMessages,
      this.authFailureOrSuccessOption});

  AuthformState copyWith(
      {bool? isSubmitting,
      bool? showValidationMessages,
      bool? sendingResetMail,
      Option<Either<AuthFailure, Unit>>? authFailureOrSuccessOption}) {
    return AuthformState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        sendingResetMail: sendingResetMail ?? this.sendingResetMail,
        showValidationMessages:
            showValidationMessages ?? this.showValidationMessages,
        authFailureOrSuccessOption:
            authFailureOrSuccessOption ?? this.authFailureOrSuccessOption);
  }
}
