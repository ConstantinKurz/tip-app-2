class Team {
  final String id;

  final String name;

  final String flagCode;

  final int winPoints;

  final bool champion;

  Team({
    required this.id,
    required this.name,
    required this.flagCode,
    required this.winPoints,
    required this.champion,
  });

  Team copyWith({
    String? id,
    String? name,
    String? flagCode,
    int? winPoints,
    bool? champion,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      flagCode: flagCode ?? this.flagCode,
      winPoints: winPoints ?? this.winPoints,
      champion: champion ?? this.champion,
    );
  }

  factory Team.empty() {
    return Team(id: "TBD", name: "Placeholder", flagCode: "Null", winPoints: 0, champion: false);
  }
}
