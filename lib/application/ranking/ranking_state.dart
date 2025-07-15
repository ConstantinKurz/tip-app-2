part of 'ranking_bloc.dart';

class RankingState {
  final List<AppUser> users;
  final AppUser? currentUser;
  final bool expanded;
  final bool isLoading;
  final RankingFailure? rankingFailure;

  const RankingState({
    required this.users,
    required this.currentUser,
    required this.expanded,
    required this.isLoading,
    required this.rankingFailure,
  });

  RankingState copyWith({
    List<AppUser>? users,
    AppUser? currentUser,
    bool? expanded,
    bool? isLoading,
    RankingFailure? rankingFailure,
  }) {
    return RankingState(
        users: users ?? this.users,
        currentUser: currentUser ?? this.currentUser,
        expanded: expanded ?? this.expanded,
        isLoading: isLoading ?? this.isLoading,
        rankingFailure: rankingFailure ?? this.rankingFailure);
  }
}

final class RankingInitial extends RankingState {
  RankingInitial()
      : super(
            users: [],
            currentUser: null,
            expanded: false,
            isLoading: true,
            rankingFailure: null);
}
