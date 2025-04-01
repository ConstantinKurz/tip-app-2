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
    on<MatchesAllEvent>((event, emit) async {
      emit(MatchesControllerLoading());
      print("no matches");
      await _matchStreamSub?.cancel();
      _matchStreamSub =
          matchRepository.watchAllMatches().listen((failureOrMatches) {
        add(MatchUpdatedEvent(failureOrMatches: failureOrMatches));
      });
      print("matches");
      print(_matchStreamSub);
    });

    on<MatchUpdatedEvent>((event, emit) {
      print("matches updated");
      event.failureOrMatches.fold(
        (failure) => emit(MatchesControllerFailure(matchFailure: failure)),
        // TODO: Add Ranking Update here
        (matches) => emit(MatchesControllerLoaded(matches: matches)),
      );
    });
  }
}
