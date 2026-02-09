import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/match_day_statistics.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/domain/usecases/validate_joker_usage_update_stat_usecase.dart';
import '../../../domain/entities/tip.dart';

part 'tipform_event.dart';
part 'tipform_state.dart';

class TipFormBloc extends Bloc<TipFormEvent, TipFormState> {
  final TipRepository tipRepository;
  final ValidateJokerUsageUpdateStatUseCase validateJokerUseCase;
  StreamSubscription<Either<TipFailure, List<Tip>>>? _userTipsSubscription;

  TipFormBloc({
    required this.tipRepository,
    required this.validateJokerUseCase,
  }) : super(const TipFormInitialState()) {
    on<TipFormInitializedEvent>(_onInitialized);
    on<TipFormFieldUpdatedEvent>(_onFieldUpdated);
    on<TipFormStreamUpdatedEvent>(_onStreamUpdated);
  }

  Future<void> _onInitialized(
    TipFormInitializedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    // ✅ Nutze Stream statt Future - reduziert Firebase Reads
    await _userTipsSubscription?.cancel();

    _userTipsSubscription = tipRepository
        .watchUserTips(event.userId)
        .listen(
          (tipResult) {
            tipResult.fold(
              (_) {
                add(TipFormStreamUpdatedEvent(
                  userId: event.userId,
                  matchId: event.matchId,
                  matchDay: event.matchDay,
                  tipHome: null,
                  tipGuest: null,
                  joker: false,
                ));
              },
              (tips) {
                final tip = tips.firstWhereOrNull((t) => t.matchId == event.matchId);

                add(TipFormStreamUpdatedEvent(
                  userId: event.userId,
                  matchId: event.matchId,
                  matchDay: event.matchDay,
                  tipHome: tip?.tipHome,
                  tipGuest: tip?.tipGuest,
                  joker: tip?.joker ?? false,
                ));
              },
            );
          },
        );
  }

  Future<void> _onFieldUpdated(
    TipFormFieldUpdatedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    emit(state.copyWith(
      isSubmitting: true,
      failureOrSuccessOption: none(),
      isLoading: false
    ));

    if (event.tipHome == null || event.tipGuest == null) {
      emit(state.copyWith(
        isSubmitting: false,
        showValidationMessages: true,
        tipGuest: event.tipGuest,
        tipHome: event.tipHome,
        joker: state.joker,
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
      points:
          null, // ✅ Points werden später durch die RecalculateMatchTipsUseCase berechnet
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

  Future<void> _onStreamUpdated(
    TipFormStreamUpdatedEvent event,
    Emitter<TipFormState> emit,
  ) async {
    emit(state.copyWith(
      userId: event.userId,
      matchId: event.matchId,
      matchDay: event.matchDay,
      tipHome: event.tipHome,
      tipGuest: event.tipGuest,
      joker: event.joker,
      isLoading: false,
    ));
  }

  @override
  Future<void> close() async {
    await _userTipsSubscription?.cancel();
    return super.close();
  }
}
