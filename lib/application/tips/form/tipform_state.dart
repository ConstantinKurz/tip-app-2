// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tipform_bloc.dart';

class TipFormState{
  final String userId;
  final String matchId;
  final int matchDay;
  final int? tipHome;
  final int? tipGuest;
  final bool joker;
  final bool isSubmitting;
  final Option<Either<TipFailure, Unit>> failureOrSuccessOption;
  final bool showValidationMessages;
  final MatchDayStatistics? matchDayStatistics;
  final bool isTipLimitReached; // Neu hinzufügen

  const TipFormState({
    required this.userId,
    required this.matchId,
    required this.matchDay,
    this.tipHome,
    this.tipGuest,
    this.joker = false,
    this.isSubmitting = false,
    this.failureOrSuccessOption = const None(),
    this.showValidationMessages = false,
    this.matchDayStatistics,
    this.isTipLimitReached = false, // Neu hinzufügen
  });

  TipFormState copyWith({
    String? userId,
    String? matchId,
    int? matchDay,
    int? tipHome,
    int? tipGuest,
    bool? joker,
    bool? isSubmitting,
    Option<Either<TipFailure, Unit>>? failureOrSuccessOption,
    bool? showValidationMessages,
    MatchDayStatistics? matchDayStatistics,
    bool? isTipLimitReached, // Neu hinzufügen
  }) {
    return TipFormState(
      userId: userId ?? this.userId,
      matchId: matchId ?? this.matchId,
      matchDay: matchDay ?? this.matchDay,
      tipHome: tipHome ?? this.tipHome,
      tipGuest: tipGuest ?? this.tipGuest,
      joker: joker ?? this.joker,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failureOrSuccessOption: failureOrSuccessOption ?? this.failureOrSuccessOption,
      showValidationMessages: showValidationMessages ?? this.showValidationMessages,
      matchDayStatistics: matchDayStatistics ?? this.matchDayStatistics,
      isTipLimitReached: isTipLimitReached ?? this.isTipLimitReached, // Neu hinzufügen
    );
  }
}

final class TipFormInitialState extends TipFormState {
  const TipFormInitialState()
      : super(
          userId: '',
          matchId: '',
          matchDay: 0,
          tipHome: null,
          tipGuest: null,
          joker: false,
          isSubmitting: false,
          showValidationMessages: false,
          failureOrSuccessOption: const None(),
          matchDayStatistics: null,
          isTipLimitReached: false,
        );
}
