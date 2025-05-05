// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'authform_bloc.dart';

class AuthformState {
  final bool isSubmitting;
  final bool sendingResetMail;
  final bool showValidationMessages;
  final Option<Either<AuthFailure, Unit>>? authFailureOrSuccessOption;

  final String? username;
  final String? championId;
  final String? email;
  final int? rank;
  final int? score;
  final int? jokerSum;

  final AppUser currentUser;

  AuthformState(
      {this.username,
      this.championId,
      this.email,
      this.rank,
      this.score,
      this.jokerSum,
      required this.isSubmitting,
      required this.sendingResetMail,
      required this.showValidationMessages,
      required this.currentUser,
      this.authFailureOrSuccessOption});

  AuthformState copyWith({
    bool? isSubmitting,
    bool? sendingResetMail,
    bool? showValidationMessages,
    Option<Either<AuthFailure, Unit>>? authFailureOrSuccessOption,
    String? username,
    String? championId,
    String? email,
    int? rank,
    int? score,
    int? jokerSum,
    AppUser? curentUser,
  }) {
    return AuthformState(
      username: username ?? this.username,
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
      currentUser: currentUser,
    );
  }
}

class AuthFormIntialState extends AuthformState {
  AuthFormIntialState()
      : super(
            username: null,
            championId: null,
            email: null,
            rank: null,
            score: null,
            jokerSum: null,
            isSubmitting: false,
            sendingResetMail: false,
            showValidationMessages: false,
            currentUser: AppUser.empty(),
            authFailureOrSuccessOption: none());
}
