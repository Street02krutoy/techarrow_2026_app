/// Domain model for a quest (matches fields shown on [QuestCard]).
class Quest {
  const Quest({
    required this.id,
    required this.name,
    required this.duration,
    required this.area,
    required this.difficulty,
    required this.imageSrc,
    this.isFavorite = false,
    this.district,
    this.checkpointsCount,
  });

  final int id;
  final bool isFavorite;
  final String name;
  final String duration;
  final String area;
  final String difficulty;
  final String imageSrc;

  /// Optional; shown on quest detail when set.
  final String? district;

  /// Optional; shown on quest detail when set.
  final int? checkpointsCount;

  Quest copyWith({
    int? id,
    bool? isFavorite,
    String? name,
    String? duration,
    String? area,
    String? difficulty,
    String? imageSrc,
    String? district,
    int? checkpointsCount,
  }) {
    return Quest(
      id: id ?? this.id,
      isFavorite: isFavorite ?? this.isFavorite,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      area: area ?? this.area,
      difficulty: difficulty ?? this.difficulty,
      imageSrc: imageSrc ?? this.imageSrc,
      district: district ?? this.district,
      checkpointsCount: checkpointsCount ?? this.checkpointsCount,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Quest &&
            other.id == id &&
            other.isFavorite == isFavorite &&
            other.name == name &&
            other.duration == duration &&
            other.area == area &&
            other.difficulty == difficulty &&
            other.imageSrc == imageSrc &&
            other.district == district &&
            other.checkpointsCount == checkpointsCount;
  }

  @override
  int get hashCode => Object.hash(
    id,
    isFavorite,
    name,
    duration,
    area,
    difficulty,
    imageSrc,
    district,
    checkpointsCount,
  );
}
