// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'matchesform_bloc.dart';

class MatchesformState {
  final bool isSubmitting;
  final bool showValidationMessages;
  final Option<Either<MatchFailure, Unit>>? matchFailureOrSuccessOption;
  MatchesformState({
    required this.isSubmitting,
    required this.showValidationMessages,
    this.matchFailureOrSuccessOption,
  });

  MatchesformState copyWith(
      {bool? isSubmitting,
      bool? showValidationMessages,
      Option<Either<MatchFailure, Unit>>? matchFailureOrSuccessOption}) {
    return MatchesformState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        showValidationMessages:
            showValidationMessages ?? this.showValidationMessages,
        matchFailureOrSuccessOption:
            matchFailureOrSuccessOption ?? this.matchFailureOrSuccessOption);
  }

  @override
  String toString() {
    return 'MatchesformState(isSubmitting: $isSubmitting, showValidationMessages: $showValidationMessages, matchFailureOrSuccessOption: $matchFailureOrSuccessOption)';
  }
}
