import 'dart:async'; // Import hinzugefügt, falls noch nicht da

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
      print("no matches"); // <-- Debug-Ausgabe 1
      await _matchStreamSub?.cancel();

      // Hier abonnieren wir den Stream vom Repository
      _matchStreamSub =
          matchRepository.watchAllMatches().listen(
        (failureOrMatches) {
          // Dieser Callback wird aufgerufen, wenn der Stream einen Wert emittiert
          print("Stream received value (matches)!"); // <-- Debug-Ausgabe 2
          // Wir fügen das UpdatedEvent hinzu, das dann den Zustand ändert
          add(MatchUpdatedEvent(failureOrMatches: failureOrMatches));
        },
        // Füge einen onError-Callback hinzu, um Stream-Fehler zu fangen
        onError: (error) {
           print('!!! Firestore stream error detected in MatchesControllerBloc: $error'); // <-- Debug-Ausgabe für Fehler
           // Hier könntest du auch ein spezielles Fehler-Event hinzufügen,
           // oder direkt einen Failure-Zustand emittieren, wenn du möchtest,
           // aber das Hinzufügen eines Events ist im Bloc-Pattern üblicher.
           // Fürs Debugging reicht das Print aber erstmal.
           // Du könntest auch versuchen, hier ein MatchUpdatedEvent mit left(UnexpectedFailure()) hinzuzufügen.
        }
      );
      print("matches listen initiated"); // <-- Debug-Ausgabe 3
      // print(_matchStreamSub); // <-- Diese Ausgabe ist nicht sehr nützlich
    });

    on<MatchUpdatedEvent>((event, emit) {
      print("MatchUpdatedEvent received!"); // <-- Debug-Ausgabe 4
      // Prüfe, was im Event enthalten ist
      event.failureOrMatches.fold(
        (failure) {
          print("MatchUpdatedEvent contained Failure: $failure"); // <-- Debug-Ausgabe 5 (Fehler)
          emit(MatchesControllerFailure(matchFailure: failure));
        },
        (matches) {
          print("MatchUpdatedEvent contained Success with ${matches.length} matches"); // <-- Debug-Ausgabe 6 (Erfolg)
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
