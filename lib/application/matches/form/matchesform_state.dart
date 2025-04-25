// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'matchesform_bloc.dart';

class MatchesformState {
  final bool isSubmitting;
  final bool showValidationMessages;
  final Option<Either<MatchFailure, Unit>>? matchFailureOrSuccessOption;

  final String? homeTeamId;
  final String? guestTeamId;
  final DateTime? matchDate;
  final TimeOfDay? matchTime;
  final int? matchDay;

  MatchesformState({
    required this.isSubmitting,
    required this.showValidationMessages,
    this.matchFailureOrSuccessOption,
    this.homeTeamId,
    this.guestTeamId,
    this.matchDate,
    this.matchTime,
    this.matchDay,
  });

  MatchesformState copyWith({
    bool? isSubmitting,
    bool? showValidationMessages,
    Option<Either<MatchFailure, Unit>>? matchFailureOrSuccessOption,
    String? homeTeamId,
    String? guestTeamId,
    DateTime? matchDate,
    TimeOfDay? matchTime,
    int? matchDay,
  }) {
    return MatchesformState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showValidationMessages: showValidationMessages ?? this.showValidationMessages,
      matchFailureOrSuccessOption: matchFailureOrSuccessOption ?? this.matchFailureOrSuccessOption,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      guestTeamId: guestTeamId ?? this.guestTeamId,
      matchDate: matchDate ?? this.matchDate,
      matchTime: matchTime ?? this.matchTime,
      matchDay: matchDay ?? this.matchDay,
    );
  }
}

class MatchesFromInitialState extends MatchesformState {
  MatchesFromInitialState()
      : super(
          isSubmitting: false,
          showValidationMessages: false,
          matchFailureOrSuccessOption: none(),
          matchDate: DateTime.now(),
          matchTime: TimeOfDay.now(),
        );
}
