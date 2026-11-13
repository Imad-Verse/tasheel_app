/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج فائدة الدرس المرتبطة بالتوقيت (LessonNoteModel)
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل فائدة علمية يدوّنها طالب العلم مرتبطة بلحظة زمنية محددة في الدرس.
/// ═══════════════════════════════════════════════════════════════════════════
class LessonNoteModel {
  final String id;
  final String lessonId;
  final String lessonTitle;
  final String bookTitle;
  final String sheikhName;
  final int timestampSeconds;
  final String content;
  final DateTime createdAt;

  const LessonNoteModel({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.bookTitle,
    required this.sheikhName,
    required this.timestampSeconds,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'bookTitle': bookTitle,
      'sheikhName': sheikhName,
      'timestampSeconds': timestampSeconds,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LessonNoteModel.fromMap(Map<String, dynamic> map) {
    return LessonNoteModel(
      id: map['id'] as String? ?? '',
      lessonId: map['lessonId'] as String? ?? '',
      lessonTitle: map['lessonTitle'] as String? ?? '',
      bookTitle: map['bookTitle'] as String? ?? '',
      sheikhName: map['sheikhName'] as String? ?? '',
      timestampSeconds: (map['timestampSeconds'] as num?)?.toInt() ?? 0,
      content: map['content'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  LessonNoteModel copyWith({
    String? id,
    String? lessonId,
    String? lessonTitle,
    String? bookTitle,
    String? sheikhName,
    int? timestampSeconds,
    String? content,
    DateTime? createdAt,
  }) {
    return LessonNoteModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      bookTitle: bookTitle ?? this.bookTitle,
      sheikhName: sheikhName ?? this.sheikhName,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// التنسيق الزمني للملاحظة (مثلاً: 05:30 أو 01:15:30)
  String get formattedTimestamp {
    final minutes = (timestampSeconds ~/ 60).remainder(60).toString().padLeft(2, '0');
    final seconds = (timestampSeconds % 60).toString().padLeft(2, '0');
    final hours = timestampSeconds ~/ 3600;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

