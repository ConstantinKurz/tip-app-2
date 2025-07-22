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
        print("Stream received value (matches)!");
        add(MatchUpdatedEvent(failureOrMatches: failureOrMatches));
      }, onError: (error) {
        print(
            '!!! Firestore stream error detected in MatchesControllerBloc: $error'); // <-- Debug-Ausgabe für Fehler
      });
      print("matches listen initiated");
    });

    on<MatchUpdatedEvent>((event, emit) {
      print("MatchUpdatedEvent received!");

      event.failureOrMatches.fold(
        (failure) {
          print("MatchUpdatedEvent contained Failure: $failure");
          emit(MatchesControllerFailure(matchFailure: failure));
        },
        (matches) {
          print(
              "MatchUpdatedEvent contained Success with ${matches.length} matches");
          print(matches);
          // TODO: Add Ranking Update here
          emit(MatchesControllerLoaded(matches: matches));
        },
      );
    });
  }

  @override
  Future<void> close() {
    _matchStreamSub?.cancel();
    return super.close();
  }
}
