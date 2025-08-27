abstract class AuthFailure{}

class ServerFailure extends AuthFailure{}

class EmailAlreadyInUseFailure extends AuthFailure{}

class InvalidEmailAndPasswordCombinationFailure extends AuthFailure{}

class InsufficientPermisssons extends AuthFailure {}

class UnexpectedAuthFailure extends AuthFailure {}

class UserNotFoundFailure extends AuthFailure {}