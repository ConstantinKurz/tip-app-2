import 'package:bloc/bloc.dart';
import 'package:flutter_web/core/failures/ranking_failure.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:meta/meta.dart';

part 'ranking_event.dart';
part 'ranking_state.dart';

class RankingBloc extends Bloc<RankingEvent, RankingState> {
  final AuthRepository authRepository;

  RankingBloc({required this.authRepository}) : super(RankingInitial()) {
    on<LoadRankingEvent>(_onLoadRanking);
  }

  Future<void> _onLoadRanking(
      LoadRankingEvent event, Emitter<RankingState> emit) async {
    emit(state.copyWith(isLoading: true));
    final userOption = await authRepository.getSignedInUser();

    final usersStream = authRepository.watchAllUsers();
    await for (final result in usersStream) {
      result.fold(
        (failure) => emit(state.copyWith(isLoading: false)),
        (users) {
          users.sort((a, b) => a.rank.compareTo(b.rank));
          emit(state.copyWith(
            users: users,
            currentUser: userOption.toNullable(),
            isLoading: false,
          ));
        },
      );
    }
  }
}

