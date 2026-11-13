/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج السلسلة / الشرح
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل شرح شيخ معين لكتاب معين (نقطة الربط بين الشيخ والكتاب).
/// يحتوي على عدد الدروس ومعرفات الربط.
/// جاهز للربط مع Firebase Firestore عبر fromMap و toMap.
/// ═══════════════════════════════════════════════════════════════════════════
class SeriesModel {
  final String id;
  final String bookId;
  final String sheikhId;
  final String categoryId;
  final String title;
  final int lessonsCount;

  const SeriesModel({
    required this.id,
    required this.bookId,
    required this.sheikhId,
    required this.categoryId,
    required this.title,
    this.lessonsCount = 0,
  });

  /// إنشاء كائن من خريطة Firestore
  factory SeriesModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return SeriesModel(
      id: docId ?? map['id'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      sheikhId: map['sheikhId'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      lessonsCount: map['lessonsCount'] as int? ?? 0,
    );
  }

  /// تحويل الكائن إلى خريطة لحفظها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'sheikhId': sheikhId,
      'categoryId': categoryId,
      'title': title,
      'lessonsCount': lessonsCount,
    };
  }

  /// إنشاء نسخة معدلة من الكائن
  SeriesModel copyWith({
    String? id,
    String? bookId,
    String? sheikhId,
    String? categoryId,
    String? title,
    int? lessonsCount,
  }) {
    return SeriesModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      sheikhId: sheikhId ?? this.sheikhId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      lessonsCount: lessonsCount ?? this.lessonsCount,
    );
  }

  @override
  String toString() => 'SeriesModel(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeriesModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

