import 'package:dartz/dartz.dart';
import 'package:flutter_web/core/failures/tip_failures.dart';
import 'package:flutter_web/domain/entities/tip.dart';

abstract class TipRepository {
  Stream<Either<TipFailure, Map<String, List<Tip>>>> watchAll();

  Stream<Either<TipFailure, List<Tip>>> watchUserTips(String userID);

  Future<Either<TipFailure, Unit>> create(Tip tip);

  Future<Either<TipFailure, Unit>> update(Tip tip);
}