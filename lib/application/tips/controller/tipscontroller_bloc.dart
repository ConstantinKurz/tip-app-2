import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:meta/meta.dart';

part 'tipscontroller_event.dart';
part 'tipscontroller_state.dart';

class TipControllerBloc extends Bloc<TipControllerEvent, TipControllerState> {
  final TipRepository tipRepository;
  StreamSubscription<Either<TipFailure, Map<String, List<Tip>>>>? _tipStreamSub;

  TipControllerBloc({
    required this.tipRepository,
  }) : super(TipControllerInitial()) {
    on<TipAllEvent>((event, emit) async {
      // print(
      //     "TipAllEvent received in TipControllerBloc. Emitting TipControllerLoading."); // <-- Debug-Ausgabe 1 für Tips
      emit(TipControllerLoading());

      // close old subs
      await _tipStreamSub?.cancel();

      // Abonnieren des Streams vom Repository
      _tipStreamSub = tipRepository.watchAll().listen((failureOrTip) {
        // print("Stream received value (tips)!"); // <-- Debug-Ausgabe 2 für Tips
        // Wir fügen das UpdatedEvent hinzu, das dann den Zustand ändert
        add(TipUpdatedEvent(failureOrTip: failureOrTip));
      },
          // Füge einen onError-Callback hinzu, um Stream-Fehler zu fangen
          onError: (error) {
        print(
            '!!! Firestore stream error detected in TipControllerBloc: $error'); // <-- Debug-Ausgabe 3 für Tips (Fehler)
        // Optional: Füge auch hier ein Event hinzu, um den Fehler zu signalisieren
        // add(TipUpdatedEvent(failureOrTip: left(UnexpectedFailure()))); // Beispiel
      });
      print("tips listen initiated"); // <-- Debug-Ausgabe 4 für Tips
    });

    // Dieser Event-Handler wird hier nicht verändert, da er keinen Stream abonniert
    on<UserTipEvent>((event, emit) async {
      print(
          "UserTipEvent received (no stream subscription here). Emitting TipControllerLoading."); // <-- Debug-Ausgabe für UserTipEvent
      emit(TipControllerLoading());
    });

    on<TipUpdatedEvent>((event, emit) {
      // print("TipUpdatedEvent received!"); // <-- Debug-Ausgabe 5 für Tips
      // Prüfe, was im Event enthalten ist
      event.failureOrTip.fold((failures) {
        print(
            "TipUpdatedEvent contained Failure: $failures"); // <-- Debug-Ausgabe 6 für Tips (Fehler)
        emit(TipControllerFailure(tipFailure: failures));
      }, (tips) {
        // Hier ist tips ein Map<String, List<Tip>>
        final totalTipLists = tips.length; // Anzahl der Benutzer mit Tipps
        int totalTipsCount = 0;
        tips.values.forEach((tipList) =>
            totalTipsCount += tipList.length); // Gesamtzahl der einzelnen Tipps
        // print(
            // "TipUpdatedEvent contained Success with $totalTipLists user tip lists and $totalTipsCount total tips."); // <-- Debug-Ausgabe 7 für Tips (Erfolg)
        emit(TipControllerLoaded(tips: tips));
      });
    });
  }

  // Diese Methode gehört direkt zur Klasse, außerhalb der on<> Blöcke
  @override
  Future<void> close() async {
    print(
        "TipControllerBloc close() called. Cancelling stream subscription."); // <-- Debug-Ausgabe beim Schließen
    await _tipStreamSub?.cancel();
    return super.close();
  }
}
