part of 'authform_bloc.dart';

@immutable
sealed class AuthFormEvent {}

class CreateUserEvent extends AuthFormEvent {
  final String? username;
  final String? password;
  final String? email;

  CreateUserEvent(
      {required this.username, required this.password, required this.email});
}
