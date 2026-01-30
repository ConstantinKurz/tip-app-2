// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tipscontroller_bloc.dart';

@immutable
abstract class TipControllerEvent {}

class TipAllEvent extends TipControllerEvent {}

class TipUpdatedEvent extends TipControllerEvent {
  final Either<TipFailure, Map<String, List<Tip>>> failureOrTip;
  TipUpdatedEvent({
    required this.failureOrTip,
  });
}

class UserTipEvent extends TipControllerEvent {}

// ✅ NEU
class TipUpdateStatisticsEvent extends TipControllerEvent {
  final String userId;
  final int matchDay;

  TipUpdateStatisticsEvent({
    required this.userId,
    required this.matchDay,
  });
}
