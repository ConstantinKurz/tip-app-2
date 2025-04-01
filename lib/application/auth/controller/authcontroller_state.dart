// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'authcontroller_bloc.dart';

@immutable
sealed class AuthControllerState {}

final class AuthControllerInitial extends AuthControllerState {}

class AuthControllerLoading extends AuthControllerState {}

class AuthControllerLoaded extends AuthControllerState {
  final List<AppUser> users;

  AuthControllerLoaded({required this.users});
}

class AuthControllerFailure extends AuthControllerState {
  final AuthFailure authFailure;
  AuthControllerFailure({
    required this.authFailure,
  });
}
