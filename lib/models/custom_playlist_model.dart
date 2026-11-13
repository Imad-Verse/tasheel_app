/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج قائمة التشغيل المخصصة / المجموعة العلمية (CustomPlaylistModel)
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل قائمة تشغيل مخصصة ينشئها طالب العلم لتجميع دروس من شروح وكتب مختلفة
/// (مثل: "دروس الطريق"، "مراجعة العقيدة") لتشغيلها بالتتابع.
/// ═══════════════════════════════════════════════════════════════════════════
class CustomPlaylistModel {
  final String id;
  final String title;
  final String? description;
  final List<String> lessonIds;
  final DateTime createdAt;

  const CustomPlaylistModel({
    required this.id,
    required this.title,
    this.description,
    this.lessonIds = const [],
    required this.createdAt,
  });

  int get lessonsCount => lessonIds.length;

  bool containsLesson(String lessonId) => lessonIds.contains(lessonId);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'lessonIds': lessonIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomPlaylistModel.fromMap(Map<String, dynamic> map) {
    return CustomPlaylistModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      lessonIds: (map['lessonIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CustomPlaylistModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? lessonIds,
    DateTime? createdAt,
  }) {
    return CustomPlaylistModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lessonIds: lessonIds ?? this.lessonIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'CustomPlaylistModel(id: $id, title: $title, lessons: ${lessonIds.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPlaylistModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

