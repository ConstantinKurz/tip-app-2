class Team {
  final String id;

  final String name;

  final int winPoints;

  final bool champion;

  Team({
    required this.id,
    required this.name,
    required this.winPoints,
    required this.champion,
  });

  Team copyWith({
    String? id,
    String? name,
    int? winPoints,
    bool? champion,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      winPoints: winPoints ?? this.winPoints,
      champion: champion ?? this.champion,
    );
  }

  factory Team.empty() {
    return Team(id: "TBD", name: "Placeholder", winPoints: 0, champion: false);
  }
}
