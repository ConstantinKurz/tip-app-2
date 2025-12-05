part of 'signupform_bloc.dart';

@immutable
sealed class SignupformEvent {}

class RegisterWithEmailAndPasswordPressed extends SignupformEvent{
  final String? email;
  final String? password;

  RegisterWithEmailAndPasswordPressed({required this.email, required this.password});
}


class SignInWithEmailAndPasswordPressed extends SignupformEvent{
  final String? email;
  final String? password;

  SignInWithEmailAndPasswordPressed({required this.email, required this.password});
}

class SendPasswordResetEvent extends SignupformEvent {
  final String email;
  
  SendPasswordResetEvent({required this.email});
}

