import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    debugPrint('🔐 [AuthBloc] CONSTRUCTOR called');

    on<SignOutPressedEvent>((event, emit) async {
      debugPrint('🔐 [AuthBloc] SignOutPressedEvent received');
      await authRepository.signOut();
      emit(AuthStateUnAuthenticated());
    });

    on<AuthCheckRequestedEvent>((event, emit) async {
      debugPrint(
          '🔐 [AuthBloc] AuthCheckRequestedEvent received - checking user...');
      final userOption = await authRepository.getSignedInUser();

      userOption.fold(() {
        debugPrint(
            '🔐 [AuthBloc] No user found -> emitting AuthStateUnAuthenticated');
        emit(AuthStateUnAuthenticated());
      }, (a) {
        debugPrint(
            '🔐 [AuthBloc] User found (${a.id}) -> emitting AuthStateAuthenticated');
        emit(AuthStateAuthenticated());
      });
    });
  }
}
