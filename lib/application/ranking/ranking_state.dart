part of 'ranking_bloc.dart';

@immutable
sealed class RankingState {}

final class RankingInitial extends RankingState {}

class RankingLoading extends RankingState {}

class RankingLoaded extends RankingState {
  final List<AppUser> sortedUsers;
  final AppUser currentUser;
  final bool expanded;

  RankingLoaded({
    required this.sortedUsers,
    required this.currentUser,
    required this.expanded,
  });

  RankingLoaded copyWith({
    List<AppUser>? sortedUsers,
    AppUser? currentUser,
    bool? expanded,
  }) {
    return RankingLoaded(
      sortedUsers: sortedUsers ?? this.sortedUsers,
      currentUser: currentUser ?? this.currentUser,
      expanded: expanded ?? this.expanded,
    );
  }
}


class RankingStateFailure extends RankingState {
  final AuthFailure rankingFailure;
  RankingStateFailure({required this.rankingFailure});
}

