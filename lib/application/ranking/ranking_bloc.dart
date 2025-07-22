import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/auth_failures.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:meta/meta.dart';

part 'ranking_event.dart';
part 'ranking_state.dart';

class RankingBloc extends Bloc<RankingEvent, RankingState> {
  final AuthRepository authRepository;
  StreamSubscription<Either<AuthFailure, List<AppUser>>>? _rankingStreamSub;

  RankingBloc({required this.authRepository}) : super(RankingInitial()) {
    on<LoadRankingEvent>((event, emit) async {
      emit(RankingLoading());

      await _rankingStreamSub?.cancel();

      _rankingStreamSub = authRepository.watchAllUsers().listen(
        (failureOrUsers) {
          add(RankingLoadedEvent(failureOrUsers: failureOrUsers));
        },
        onError: (error) {
          print('🔥 Ranking stream error: $error');
          add(RankingLoadedEvent(
            failureOrUsers: left(UnexpectedAuthFailure()),
          ));
        },
      );
    });

    on<ToggleRankingViewEvent>((event, emit) {
      if (state is RankingLoaded) {
        final current = state as RankingLoaded;
        emit(current.copyWith(expanded: !current.expanded));
      }
    });

    on<RankingLoadedEvent>((event, emit) async {
      final signedInUser = await authRepository.getSignedInUser();
      //get last emitted rankingloaded
      final currentExpanded = state is RankingLoaded ? (state as RankingLoaded).expanded : false;

      event.failureOrUsers.fold(
        (failure) => emit(RankingStateFailure(rankingFailure: failure)),
        (users) {
          users.sort((a, b) => a.rank.compareTo(b.rank));

          emit(RankingLoaded(
            sortedUsers: users,
            currentUser: signedInUser.getOrElse(() => users.first),
            expanded: currentExpanded
          ));
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await _rankingStreamSub?.cancel();
    return super.close();
  }
}
