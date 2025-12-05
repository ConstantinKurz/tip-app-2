abstract class AuthFailure{}

class ServerFailure extends AuthFailure{}

class EmailAlreadyInUseFailure extends AuthFailure{}

class InvalidEmailAndPasswordCombinationFailure extends AuthFailure{}

class InsufficientPermisssons extends AuthFailure {}

class UnexpectedAuthFailure extends AuthFailure {}

class UserNotFoundFailure extends AuthFailure {
    final String message;

  UserNotFoundFailure({required this.message});
}

class InvalidEmailFailure extends AuthFailure {
    final String message;

  InvalidEmailFailure({required this.message});
}

class InvalidCredential extends AuthFailure {
  final String message;

  InvalidCredential({required this.message});
}