// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tipform_bloc.dart';

abstract class TipFormEvent {}

class TipFormInitializedEvent extends TipFormEvent {
  final String userId;
  final String matchId;
  final int matchDay;

  TipFormInitializedEvent({
    required this.userId,
    required this.matchId,
    required this.matchDay,
  });
}

class TipFormFieldUpdatedEvent extends TipFormEvent {
  final String userId;
  final String matchId;
  final int matchDay;
  final int? tipHome;
  final int? tipGuest;
  final bool? joker;

  TipFormFieldUpdatedEvent({
    required this.userId,
    required this.matchId,
    required this.matchDay,
    this.tipHome,
    this.tipGuest,
    this.joker,
  });
}

class TipFormJokerValidationEvent extends TipFormEvent {
  final String userId;
  final int matchDay;

  TipFormJokerValidationEvent({
    required this.userId,
    required this.matchDay,
  });
}

class TipFormStreamUpdatedEvent extends TipFormEvent {
  final String userId;
  final String matchId;
  final int matchDay;
  final int? tipHome;
  final int? tipGuest;
  final bool joker;

  TipFormStreamUpdatedEvent({
    required this.userId,
    required this.matchId,
    required this.matchDay,
    this.tipHome,
    this.tipGuest,
    required this.joker,
  });
}

/// Event für externe Updates vom TipControllerBloc
/// Vermeidet separate Firebase-Streams pro TipCard
class TipFormExternalUpdateEvent extends TipFormEvent {
  final String matchId;
  final int matchDay;
  final int? tipHome;
  final int? tipGuest;
  final bool joker;

  TipFormExternalUpdateEvent({
    required this.matchId,
    required this.matchDay,
    this.tipHome,
    this.tipGuest,
    this.joker = false,
  });
}
