part of 'ranking_bloc.dart';

class RankingState {
  final List<AppUser> users;
  final AppUser? currentUser;
  final bool expanded;
  final bool isLoading;

  const RankingState({
    required this.users,
    required this.currentUser,
    required this.expanded,
    required this.isLoading,
  });

  RankingState copyWith({
    List<AppUser>? users,
    AppUser? currentUser,
    bool? expanded,
    bool? isLoading,
  }) {
    return RankingState(
      users: users ?? this.users,
      currentUser: currentUser ?? this.currentUser,
      expanded: expanded ?? this.expanded,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final class RankingStateInitial extends RankingState {
  RankingStateInitial()
      : super(users: [], currentUser: null, expanded: false, isLoading: true);
}
