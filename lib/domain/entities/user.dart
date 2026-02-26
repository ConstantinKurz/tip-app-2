// ignore_for_file: public_member_api_docs, sort_constructors_first
// change code
class AppUser {
  final String id;
  final String championId;
  final String email;
  final String name;
  final int rank;
  final int score;
  final int jokerSum;
  final int sixer;
  final bool admin;

  AppUser({
    required this.id,
    required this.championId,
    required this.email,
    required this.name,
    required this.rank,
    required this.score,
    required this.jokerSum,
    required this.sixer,
    required this.admin,
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
      admin: false,
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
    bool? admin,
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
      admin: admin ?? this.admin,
    );
  }
}
