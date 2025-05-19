// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tipform_bloc.dart';

@immutable
abstract class TipFormEvent {}

class TipFormFieldUpdatedEvent extends TipFormEvent {
  final String? id;
  final String? userId;
  final String? matchId;
  final DateTime? tipDate;
  final int? tipHome;
  final int? tipGuest;
  final bool? joker;

  TipFormFieldUpdatedEvent(
      {this.id,
      this.userId,
      this.matchId,
      this.tipDate,
      this.tipHome,
      this.tipGuest,
      this.joker});
}
