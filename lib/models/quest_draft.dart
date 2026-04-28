class QuestDraft {
  const QuestDraft({
    required this.id,
    required this.title,
    required this.location,
    required this.difficulty,
    required this.durationMinutes,
    required this.description,
    required this.rulesAndWarnings,
    required this.checkpointsCount,
    required this.updatedAtIso,
    this.imageBase64,
  });

  final String id;
  final String title;
  final String location;
  final int difficulty;
  final int durationMinutes;
  final String description;
  final String rulesAndWarnings;
  final int checkpointsCount;
  final String updatedAtIso;
  final String? imageBase64;

  factory QuestDraft.fromJson(Map<String, dynamic> json) {
    return QuestDraft(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: json['location'] as String? ?? '',
      difficulty: json['difficulty'] as int? ?? 1,
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      rulesAndWarnings: json['rulesAndWarnings'] as String? ?? '',
      checkpointsCount: json['checkpointsCount'] as int? ?? 0,
      updatedAtIso: json['updatedAtIso'] as String? ?? '',
      imageBase64: json['imageBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'location': location,
      'difficulty': difficulty,
      'durationMinutes': durationMinutes,
      'description': description,
      'rulesAndWarnings': rulesAndWarnings,
      'checkpointsCount': checkpointsCount,
      'updatedAtIso': updatedAtIso,
      'imageBase64': imageBase64,
    };
  }

  QuestDraft copyWith({
    String? id,
    String? title,
    String? location,
    int? difficulty,
    int? durationMinutes,
    String? description,
    String? rulesAndWarnings,
    int? checkpointsCount,
    String? updatedAtIso,
    String? imageBase64,
  }) {
    return QuestDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      difficulty: difficulty ?? this.difficulty,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      description: description ?? this.description,
      rulesAndWarnings: rulesAndWarnings ?? this.rulesAndWarnings,
      checkpointsCount: checkpointsCount ?? this.checkpointsCount,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}
