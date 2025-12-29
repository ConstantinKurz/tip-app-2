// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'authform_bloc.dart';

@immutable
sealed class AuthFormEvent {}

class CreateUserEvent extends AuthFormEvent {
  final String? username;
  final String? email;
  final String? password;
  final bool admin;

  CreateUserEvent({
    this.username,
    this.email,
    this.password,
    this.admin = false,
  });
}

class UserFormFieldUpdatedEvent extends AuthFormEvent {
  final String? username;
  final String? email;
  final bool? admin;
  final String? championId;
  final int? rank;
  final int? score;
  final int? jokerSum;
  final int? sixer;
  UserFormFieldUpdatedEvent({
    this.username,
    this.email,
    this.admin,
    this.championId,
    this.rank,
    this.score,
    this.jokerSum,
    this.sixer
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

class UpdateUserWithPasswordEvent extends AuthFormEvent {
  final AppUser user;
  final AppUser currentUser;
  final String? currentPassword;
  final String? newPassword;
  
  UpdateUserWithPasswordEvent({
    required this.user,
    required this.currentUser,
    this.currentPassword,
    this.newPassword,
  });
}