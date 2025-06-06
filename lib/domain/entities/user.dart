// ignore_for_file: public_member_api_docs, sort_constructors_first


class AppUser {
  final String championId;
  final String username;
  final String email;
  final int rank;
  final int score;
  final int jokerSum;
  AppUser({
    required this.championId,
    required this.username,
    required this.email,
    required this.rank,
    required this.score,
    required this.jokerSum,
  });

  factory AppUser.empty() {
    return AppUser(
      championId: 'TBD',
      username: '',
      email: '',
      rank: 0,
      score: 0,
      jokerSum: 0,
    );
  }

  AppUser copyWith({
    String? championId,
    String? username,
    String? email,
    int? rank,
    int? score,
    int? jokerSum,
  }) {
    return AppUser(
      championId: championId ?? this.championId,
      username: username ?? this.username,
      email: email ?? this.email,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      jokerSum: jokerSum ?? this.jokerSum,
    );
  }
}
