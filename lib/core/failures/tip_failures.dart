import 'package:flutter_web/domain/entities/match_phase.dart';

abstract class TipFailure {}

class InsufficientPermisssons extends TipFailure {}

class UnexpectedFailure extends TipFailure {}

class InCompleteInputFailure extends TipFailure {}

class NotFoundFailure extends TipFailure {}

class ServerFailure extends TipFailure {
  final String message;
  ServerFailure({required this.message});
  
  @override
  String toString() => message;
}

class JokerLimitReachedFailure extends TipFailure {
  final int used;
  final int limit;
  final int matchDay;
  
  JokerLimitReachedFailure({
    required this.used,
    required this.limit,
    required this.matchDay,
  });
  
  @override
  String toString() {
    final phase = MatchPhase.fromMatchDay(matchDay);
    return 'Joker-Limit erreicht in ${phase.displayName}: $used/$limit verwendet';
  }
}