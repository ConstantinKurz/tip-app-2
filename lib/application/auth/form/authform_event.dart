// ignore_for_file: public_member_api_docs, sort_constructors_first
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

class UserFormFieldUpdatedEvent extends AuthFormEvent {
  final String? username;
  final String? championId;
  final int? rank;
  final int? score;
  final int? jokerSum;
  UserFormFieldUpdatedEvent({
    this.username,
    this.championId,
    this.rank,
    this.score,
    this.jokerSum,
  });
}

class UpdateUserEvent extends AuthFormEvent {
  final AppUser? currentUser;
  final AppUser? user;
  UpdateUserEvent({
    this.currentUser,
    this.user,
  });
}

class DeleteUserEvent extends AuthFormEvent {
  final String id;
  DeleteUserEvent({
    required this.id,
  });
}