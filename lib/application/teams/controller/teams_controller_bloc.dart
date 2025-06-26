import 'dart:async'; // Import hinzugefügt, falls noch nicht da

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/team_failures.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:meta/meta.dart';

part 'teams_controller_event.dart';
part 'teams_controller_state.dart';

class TeamsControllerBloc extends Bloc<TeamsControllerEvent, TeamsControllerState> {
  final TeamRepository teamRepository;
  StreamSubscription<Either<TeamFailure, List<Team>>>? _teamStreamSubscription;

  TeamsControllerBloc({required this.teamRepository}) : super(TeamsControllerInitial()) {
    on<TeamsControllerAllEvent>((event, emit) async {
      emit(TeamsControllerLoading());
      print("TeamsAllEvent received in TeamsBloc. Emitting TeamsLoading."); // <-- Debug-Ausgabe 1 für Teams
      await _teamStreamSubscription?.cancel();

      // Hier abonnieren wir den Stream vom Repository
      _teamStreamSubscription =
          teamRepository.watchAllTeams().listen(
        (failureOrTeams) {
          // Dieser Callback wird aufgerufen, wenn der Stream einen Wert emittiert
          print("Stream received value (teams)!"); // <-- Debug-Ausgabe 2 für Teams
          // Wir fügen das UpdatedEvent hinzu, das dann den Zustand ändert
          add(TeamsControllerUpdatedEvent(failureOrTeams: failureOrTeams));
        },
        // Füge einen onError-Callback hinzu, um Stream-Fehler zu fangen
        onError: (error) {
           print('!!! Firestore stream error detected in TeamsBloc: $error'); // <-- Debug-Ausgabe 3 für Teams (Fehler)
           // Du könntest hier auch ein TeamUpdatedEvent mit left(UnexpectedFailure()) hinzufügen,
           // um den Fehler über den normalen Event-Kanal zu verarbeiten.
        }
      );
       print("teams listen initiated"); // <-- Debug-Ausgabe 4 für Teams
    });

    on<TeamsControllerUpdatedEvent>((event, emit) {
      print("TeamsUpdatedEvent received!"); // <-- Debug-Ausgabe 5 für Teams
      // Prüfe, was im Event enthalten ist
      event.failureOrTeams.fold(
          (failure) {
            print("TeamsUpdatedEvent contained Failure: $failure"); // <-- Debug-Ausgabe 6 für Teams (Fehler)
            emit(TeamsControllerFailureState(teamFailure: failure));
          },
          (teams) {
            print("TeamsUpdatedEvent contained Success with ${teams.length} teams"); // <-- Debug-Ausgabe 7 für Teams (Erfolg)
            emit(TeamsControllerLoaded(teams: teams));
          });
    });
  }

  @override
  Future<void> close() {
    _teamStreamSubscription?.cancel();
    return super.close();
  }
}
