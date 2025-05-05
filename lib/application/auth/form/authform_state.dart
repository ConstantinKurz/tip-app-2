// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'authform_bloc.dart';

class AuthformState {
  final bool isSubmitting;
  final bool sendingResetMail;
  final bool showValidationMessages;
  final Option<Either<AuthFailure, Unit>>? authFailureOrSuccessOption;

  final String? username;
  final String? password;
  final String? championId;
  final String? email;
  final int? rank;
  final int? score;
  final int? jokerSum;

  AuthformState(
      {this.username,
      this.password,
      this.championId,
      this.email,
      this.rank,
      this.score,
      this.jokerSum,
      required this.isSubmitting,
      required this.sendingResetMail,
      required this.showValidationMessages,
      this.authFailureOrSuccessOption});

  AuthformState copyWith({
    bool? isSubmitting,
    bool? sendingResetMail,
    bool? showValidationMessages,
    Option<Either<AuthFailure, Unit>>? authFailureOrSuccessOption,
    String? username,
    String? password,
    String? championId,
    String? email,
    int? rank,
    int? score,
    int? jokerSum,
  }) {
    return AuthformState(
      username: username ?? this.username,
      password: password ?? this.password,
      championId: championId ?? this.championId,
      email: email ?? this.email,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      jokerSum: jokerSum ?? this.jokerSum,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      sendingResetMail: sendingResetMail ?? this.sendingResetMail,
      showValidationMessages:
          showValidationMessages ?? this.showValidationMessages,
      authFailureOrSuccessOption:
          authFailureOrSuccessOption ?? this.authFailureOrSuccessOption,
    );
  }
}

class AuthFormIntialState extends AuthformState {
  AuthFormIntialState()
      : super(
            username: null,
            championId: null,
            password: null,
            email: null,
            rank: null,
            score: null,
            jokerSum: null,
            isSubmitting: false,
            sendingResetMail: false,
            showValidationMessages: false,
            authFailureOrSuccessOption: none());
}
