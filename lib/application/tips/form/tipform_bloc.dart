import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match_day_statistics.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/usecases/validate_joker_usage_usecase.dart';
import 'package:meta/meta.dart';
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
    on<TipFormJokerValidationEvent>(_onJokerValidation);
  }

  Future<void> _onInitialized(
    TipFormInitializedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    final userTipsResult = await tipRepository.getTipsByUserId(event.userId);
    final tipData = userTipsResult.fold(
      (failure) => null,
      (tips) => tips.firstWhereOrNull((tip) => tip.matchId == event.matchId),
    );

    final statsResult = await validateJokerUseCase(
      userId: event.userId,
      matchDay: event.matchDay,
    );
    final stats = statsResult.fold(
      (_) => null,
      (result) => result,
    );

    // Prüfe ob Tipp-Limit erreicht (nur Gruppenphase, matchDay 1-3)
    bool isTipLimitReached = false;
    if (event.matchDay <= 3 && stats != null) {
      isTipLimitReached = stats.tippedGames >= 20; //Limit 20 in Gruppenphase
    }

    emit(
      TipFormState(
        userId: event.userId,
        matchId: event.matchId,
        matchDay: event.matchDay,
        tipHome: tipData?.tipHome,
        tipGuest: tipData?.tipGuest,
        joker: tipData?.joker ?? false,
        matchDayStatistics: stats,
        isTipLimitReached: isTipLimitReached,
      ),
    );
  }

  Future<void> _onFieldUpdated(
    TipFormFieldUpdatedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));

    final isTipHomeNull = event.tipHome == null;
    final isTipGuestNull = event.tipGuest == null;

    // Wenn beide leer, nicht speichern - nur State zurücksetzen
    if (isTipHomeNull && isTipGuestNull) {
      emit(state.copyWith(
        tipGuest: null,
        tipHome: null,
        joker: false,
        isSubmitting: false,
        failureOrSuccessOption: none(),
      ));
      return;
    }

    if (isTipHomeNull || isTipGuestNull) {
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

    // Joker-Validierung basierend auf matchDay
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
        final result = validationResult.getOrElse(
          () => MatchDayStatistics(
            matchDay: 0,
            tippedGames: 0,
            totalGames: 0,
            jokersUsed: 0,
            jokersAvailable: 0,
          ),
        );
        
        emit(state.copyWith(
          isSubmitting: false,
          showValidationMessages: true,
          matchDayStatistics: result,
          failureOrSuccessOption: some(
            left(JokerLimitReachedFailure(
              used: result.jokersUsed,
              limit: result.jokersAvailable,
              matchDay: result.matchDay,
            ))
          ),
        ));
        return;
      }

      // Joker validiert - State aktualisieren
      emit(
        state.copyWith(
          matchDayStatistics: validationResult.fold((_) => null, (r) => r),
        ),
      );
    }

    final newTip = Tip.empty(event.userId).copyWith(
      id: "${event.userId}_${event.matchId}",
      matchId: event.matchId,
      tipHome: event.tipHome,
      tipGuest: event.tipGuest,
      joker: event.joker,
    );
    final result = await tipRepository.create(newTip);

    emit(state.copyWith(
      tipGuest: event.tipGuest,
      tipHome: event.tipHome,
      joker: event.joker,
      isSubmitting: false,
      failureOrSuccessOption: optionOf(result),
    ));
  }

  Future<void> _onJokerValidation(
    TipFormJokerValidationEvent event,
    Emitter<TipFormState> emit,
  ) async {
    final validationResult = await validateJokerUseCase(
      userId: event.userId,
      matchDay: event.matchDay,
    );

    emit(
      state.copyWith(
        matchDayStatistics: validationResult.fold(
          (_) => null,
          (result) => result,
        ),
      ),
    );
  }
}