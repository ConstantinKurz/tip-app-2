// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tipform_bloc.dart';

@immutable
abstract class TipFormEvent {}

class InitializeTipFormPage extends TipFormEvent {
  final Tip? tip;
  InitializeTipFormPage({required this.tip});
}


class TipChangedEvent extends TipFormEvent {
  final Tip? tip;
  TipChangedEvent({
    this.tip,
  }); 
}

class JokerChangedEvent extends TipFormEvent {
    final Tip? tip;
  JokerChangedEvent({
    this.tip,
  });
}
