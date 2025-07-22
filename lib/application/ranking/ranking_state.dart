part of 'ranking_bloc.dart';

@immutable
sealed class RankingState {}

final class RankingInitial extends RankingState {}

class RankingLoading extends RankingState {}

class RankingLoaded extends RankingState {
  final List<AppUser> sortedUsers;
  final AppUser currentUser;

  RankingLoaded({required this.sortedUsers, required this.currentUser});
}

class RankingFailure extends RankingFailure
