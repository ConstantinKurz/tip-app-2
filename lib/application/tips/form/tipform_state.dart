// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tipform_bloc.dart';

class TipFormState {
  final String? id;
  final String? userId;
  final String? matchId;
  final DateTime? tipDate;
  final int? tipHome;
  final int? tipGuest;
  final bool? joker;
  final bool showValidationMessages;
  final bool isSubmitting;
  final Option<Either<TipFailure, Unit>> failureOrSuccessOption;
  TipFormState({
    this.id,
    this.userId,
    this.matchId,
    required this.tipDate,
    this.tipHome,
    this.tipGuest,
    this.joker,
    required this.showValidationMessages,
    required this.isSubmitting,
    required this.failureOrSuccessOption,
  });

  TipFormState copyWith({
    String? id,
    String? userId,
    String? matchId,
    DateTime? tipDate,
    int? tipHome,
    int? tipGuest,
    bool? joker,
    bool? showValidationMessages,
    bool? isSubmitting,
    Option<Either<TipFailure, Unit>>? failureOrSuccessOption,
  }) {
    return TipFormState(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      matchId: matchId ?? this.matchId,
      tipDate: tipDate ?? this.tipDate,
      tipHome: tipHome ?? this.tipHome,
      tipGuest: tipGuest ?? this.tipGuest,
      joker: joker ?? this.joker,
      showValidationMessages:
          showValidationMessages ?? this.showValidationMessages,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failureOrSuccessOption:
          failureOrSuccessOption ?? this.failureOrSuccessOption,
    );
  }
}

final class TipFormInitialState extends TipFormState {
  TipFormInitialState()
      : super(
            id: null,
            userId: null,
            matchId: null,
            tipDate: null,
            tipGuest: null,
            tipHome: null,
            isSubmitting: false,
            showValidationMessages: false,
            failureOrSuccessOption: none());
}
