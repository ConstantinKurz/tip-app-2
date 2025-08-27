import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/match_failures.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:meta/meta.dart';

part 'matchescontroller_event.dart';
part 'matchescontroller_state.dart';

class MatchesControllerBloc
    extends Bloc<MatchesControllerEvent, MatchesControllerState> {
  final MatchRepository matchRepository;
  StreamSubscription<Either<MatchFailure, List<CustomMatch>>>? _matchStreamSub;

  MatchesControllerBloc({required this.matchRepository})
      : super(MatchesControllerInitial()) {
    on<MatchesAllEvent>(_onMatchesAllEvent);
    on<MatchUpdatedEvent>(_onMatchUpdatedEvent);
  }

  Future<void> _onMatchesAllEvent(
    MatchesAllEvent event,
    Emitter<MatchesControllerState> emit,
  ) async {
    emit(MatchesControllerLoading());

    await _matchStreamSub?.cancel();

    _matchStreamSub = matchRepository.watchAllMatches().listen(
      (failureOrMatches) =>
          add(MatchUpdatedEvent(failureOrMatches: failureOrMatches)),
      onError: (_) {
        // Sollte selten vorkommen, da das Repository schon mapFirebaseError nutzt
        emit(MatchesControllerFailure(matchFailure: UnexpectedFailure()));
      },
    );
  }

  void _onMatchUpdatedEvent(
    MatchUpdatedEvent event,
    Emitter<MatchesControllerState> emit,
  ) {
    event.failureOrMatches.fold(
      (failure) => emit(MatchesControllerFailure(matchFailure: failure)),
      (matches) => emit(MatchesControllerLoaded(matches: matches)),
    );
  }

  @override
  Future<void> close() {
    _matchStreamSub?.cancel();
    return super.close();
  }
}
