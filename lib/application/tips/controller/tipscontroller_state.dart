part of 'tipscontroller_bloc.dart';

@immutable
sealed class TipControllerState {}

final class TipControllerInitial extends TipControllerState {}


final class TipControllerLoading extends TipControllerState {}

class TipControllerFailure extends TipControllerState {
  final TipFailure tipFailure;
  TipControllerFailure({
    required this.tipFailure,
  });
}

final class TipControllerLoaded extends TipControllerState {
  final Map<String, List<Tip>> tips;
  TipControllerLoaded({
    required this.tips
  });
}

