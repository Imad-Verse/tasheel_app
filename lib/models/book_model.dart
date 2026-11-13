/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج الكتاب / المتن
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل كتاباً أو متناً علمياً مع ربطه بالقسم وعدد الشروحات.
/// جاهز للربط مع Firebase Firestore عبر fromMap و toMap.
/// ═══════════════════════════════════════════════════════════════════════════
class BookModel {
  final String id;
  final String categoryId;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final int seriesCount;

  const BookModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.author,
    this.description = '',
    this.coverUrl = '',
    this.seriesCount = 0,
  });

  /// إنشاء كائن من خريطة Firestore
  factory BookModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return BookModel(
      id: docId ?? map['id'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      description: map['description'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      seriesCount: map['seriesCount'] as int? ?? 0,
    );
  }

  /// تحويل الكائن إلى خريطة لحفظها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'author': author,
      'description': description,
      'coverUrl': coverUrl,
      'seriesCount': seriesCount,
    };
  }

  /// إنشاء نسخة معدلة من الكائن
  BookModel copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    int? seriesCount,
  }) {
    return BookModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      seriesCount: seriesCount ?? this.seriesCount,
    );
  }

  @override
  String toString() => 'BookModel(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

