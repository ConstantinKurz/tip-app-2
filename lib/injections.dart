import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/auth/form/authform_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/application/ranking/ranking_bloc.dart';
import 'package:flutter_web/application/signupform/signupform_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/teams/form/teamsform_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/repositories/match_repository.dart';
import 'package:flutter_web/domain/repositories/team_repository.dart';
import 'package:flutter_web/infrastructure/repositories/match_repository_impl.dart';
import 'package:flutter_web/infrastructure/repositories/team_repository_impl.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_web/domain/repositories/auth_repository.dart';
import 'package:flutter_web/domain/repositories/tip_repository.dart';
import 'package:flutter_web/infrastructure/repositories/auth_repository_impl.dart';
import 'package:flutter_web/infrastructure/repositories/tip_repository_impl.dart';

final sl = GetIt.I; // sl == service locator

Future<void> init() async {
  // Register external dependencies
  final firebaseAuth = FirebaseAuth.instance;
  final firebaseFirestore = FirebaseFirestore.instance;
  sl.registerLazySingleton(() => firebaseAuth);
  sl.registerLazySingleton(() => firebaseFirestore);

  // Register repositories
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(firebaseAuth: sl()));
  
  sl.registerLazySingleton<TipRepository>(
      () => TipRepositoryImpl(firebaseFirestore: sl(), authRepository: sl()));

  sl.registerLazySingleton<MatchRepository>(
      () => MatchRepositoryImpl());

  sl.registerLazySingleton<TeamRepository>(() => TeamRepositoryImpl());
  // Register Blocs
  sl.registerFactory(() => SignupformBloc(authRepository: sl()));
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => AuthControllerBloc(authRepository: sl()));
  sl.registerFactory(() => MatchesformBloc(matchesRepository: sl()));
  sl.registerFactory(() => MatchesControllerBloc(matchRepository: sl()));
  sl.registerFactory(() => TipControllerBloc(tipRepository: sl()));
  sl.registerFactory(() => TeamsControllerBloc(teamRepository: sl()));
  sl.registerFactory(() => TeamsformBloc(teamRepository: sl()));
  sl.registerFactory(() => TipFormBloc(tipRepository: sl()));
  sl.registerFactory(() => AuthformBloc(authRepository: sl()));
  sl.registerFactory(() => RankingBloc());

  // Register other services if necessary
}
