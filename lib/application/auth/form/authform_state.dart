// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'authform_bloc.dart';

class AuthformState {
  final bool isSubmitting;
  final bool sendingResetMail;
  final bool showValidationMessages;
  final Option<Either<AuthFailure, Unit>>? authFailureOrSuccessOption;

  final String? id;
  final String? name;
  final String? championId;
  final String? email;
  final int? rank;
  final int? score;
  final int? jokerSum;
  final int? sixer;

  final AppUser currentUser;

  AuthformState(
      {this.id,
      this.name,
      this.championId,
      this.email,
      this.rank,
      this.score,
      this.jokerSum,
      this.sixer,
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
    String? id,
    String? name,
    String? championId,
    String? email,
    int? rank,
    int? score,
    int? jokerSum,
    int? sixer,
    AppUser? curentUser,
  }) {
    return AuthformState(
      id: id ?? this.id,
      name: name ?? this.name,
      championId: championId ?? this.championId,
      email: email ?? this.email,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      jokerSum: jokerSum ?? this.jokerSum,
      sixer: sixer ?? this.sixer,
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
            id: null,
            name: null,
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
