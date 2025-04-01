import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'authform_event.dart';
part 'authform_state.dart';

class AuthformBloc extends Bloc<AuthformEvent, AuthformState> {
  AuthformBloc() : super(AuthformInitial()) {
    on<AuthformEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
