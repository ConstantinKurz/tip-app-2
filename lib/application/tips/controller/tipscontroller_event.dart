// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tipscontroller_bloc.dart';

@immutable
abstract class TipControllerEvent {}

class TipLoadForUserEvent extends TipControllerEvent {
  final String userId;

  TipLoadForUserEvent({required this.userId});
}

class TipAllEvent extends TipControllerEvent {}

class TipUpdatedEvent extends TipControllerEvent { // ✅ NEU
  final Either<TipFailure, dynamic> failureOrTip;
  final String? userId;

  TipUpdatedEvent({
    required this.failureOrTip,
    this.userId,
  });
}

class TipUpdateStatisticsEvent extends TipControllerEvent {
  final String userId;
  final int matchDay;

  TipUpdateStatisticsEvent({
    required this.userId,
    required this.matchDay,
  });
}
