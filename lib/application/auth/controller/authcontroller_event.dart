part of 'authcontroller_bloc.dart';

abstract class AuthControllerEvent {}

class AuthAllEvent extends AuthControllerEvent {}

class CreateAuthEvent extends AuthControllerEvent {}


class AuthUpdatedEvent extends AuthControllerEvent {
  final Either<AuthFailure, List<AppUser>> failureOrUsers;
  AuthUpdatedEvent({
    required this.failureOrUsers,
  });
}