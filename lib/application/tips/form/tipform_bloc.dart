import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match_day_statistics.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/usecases/validate_joker_usage_usecase.dart';
import '../../../domain/entities/tip.dart';

part 'tipform_event.dart';
part 'tipform_state.dart';

class TipFormBloc extends Bloc<TipFormEvent, TipFormState> {
  final TipRepository tipRepository;
  final ValidateJokerUsageUseCase validateJokerUseCase;

  TipFormBloc({
    required this.tipRepository,
    required this.validateJokerUseCase,
  }) : super(const TipFormInitialState()) {
    on<TipFormInitializedEvent>(_onInitialized);
    on<TipFormFieldUpdatedEvent>(_onFieldUpdated);
  }

  Future<void> _onInitialized(
    TipFormInitializedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    // Hole existierenden Tip
    final existingTips = await tipRepository.getTipsByUserId(event.userId);
    final tip = existingTips.fold(
      (_) => null,
      (tips) => tips.firstWhereOrNull((t) => t.matchId == event.matchId),
    );

    // Emittiere State ohne Statistiken (werden zentral geladen)
    emit(
      TipFormState(
        userId: event.userId,
        matchId: event.matchId,
        matchDay: event.matchDay,
        tipHome: tip?.tipHome,
        tipGuest: tip?.tipGuest,
        joker: tip?.joker ?? false,
      ),
    );
  }

  Future<void> _onFieldUpdated(
    TipFormFieldUpdatedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      failureOrSuccessOption: none(),
    ));

    if (event.tipHome == null || event.tipGuest == null) {
      emit(state.copyWith(
        isSubmitting: false,
        showValidationMessages: true,
        tipGuest: event.tipGuest,
        tipHome: event.tipHome,
        joker: event.joker,
        failureOrSuccessOption: some(left(InCompleteInputFailure())),
      ));
      return;
    }

    // Joker-Validierung nur prüfen
    if (event.joker ?? false) {
      final validationResult = await validateJokerUseCase(
        userId: event.userId,
        matchDay: event.matchDay,
      );

      final isValid = validationResult.fold(
        (_) => false,
        (result) => result.isJokerAvailable,
      );

      if (!isValid) {
        final stats = validationResult.getOrElse(
          () => MatchDayStatistics(
            matchDay: event.matchDay,
            tippedGames: 0,
            totalGames: 0,
            jokersUsed: 0,
            jokersAvailable: 0,
          ),
        );

        emit(state.copyWith(
          isSubmitting: false,
          showValidationMessages: true,
          failureOrSuccessOption: some(
            left(JokerLimitReachedFailure(
              used: stats.jokersUsed,
              limit: stats.jokersAvailable,
              matchDay: event.matchDay,
            )),
          ),
        ));
        return;
      }
    }

    // Erstelle oder aktualisiere Tip
    final tip = Tip(
      id: "${event.userId}_${event.matchId}",
      userId: event.userId,
      matchId: event.matchId,
      tipDate: DateTime.now(),
      tipHome: event.tipHome,
      tipGuest: event.tipGuest,
      joker: event.joker ?? false,
      points: null, // ✅ Points werden später durch die RecalculateMatchTipsUseCase berechnet
    );

    final result = await tipRepository.create(tip);

    emit(state.copyWith(
      isSubmitting: false,
      tipHome: event.tipHome,
      tipGuest: event.tipGuest,
      joker: event.joker,
      showValidationMessages: true,
      failureOrSuccessOption: some(result),
    ));
  }
}
