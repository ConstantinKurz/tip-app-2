part of 'ranking_bloc.dart';

@immutable

class RankingState {
  final bool expanded;

  const RankingState({required this.expanded});

  RankingState copyWith({bool? expanded}) {
    return RankingState(
      expanded: expanded ?? this.expanded,
    );
  }
}
