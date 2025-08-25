// ignore_for_file: public_member_api_docs, sort_constructors_first

class AppUser {
  final String id;
  final String championId;
  final String email;
  final String name;
  final int rank;
  final int score;
  final int jokerSum;
  final int sixer;

  AppUser({
    required this.id,
    required this.championId,
    required this.email,
    required this.name,
    required this.rank,
    required this.score,
    required this.jokerSum,
    required this.sixer,
  });

  factory AppUser.empty() {
    return AppUser(
      id: '',
      championId: 'TBD',
      email: '',
      name: '',
      rank: 0,
      score: 0,
      jokerSum: 0,
      sixer: 0,
    );
  }

  AppUser copyWith({
    String? id,
    String? championId,
    String? email,
    String? name,
    int? rank,
    int? score,
    int? jokerSum,
    int? sixer,
  }) {
    return AppUser(
      id: id ?? this.id,
      championId: championId ?? this.championId,
      email: email ?? this.email,
      name: name ?? this.name,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      jokerSum: jokerSum ?? this.jokerSum,
      sixer: sixer ?? this.sixer,
    );
  }
}
