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

/// Internes Event für debounced Updates (nach 3s Stabilität)
class _DebouncedUpdateEvent extends AuthControllerEvent {
  final List<AppUser> users;
  final AppUser? signedInUser;
  _DebouncedUpdateEvent({required this.users, this.signedInUser});
}
