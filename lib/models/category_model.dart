/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج القسم العلمي
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل الأقسام الرئيسية مثل: العقيدة، الفقه، الحديث، إلخ.
/// جاهز للربط مع Firebase Firestore عبر fromMap و toMap.
/// ═══════════════════════════════════════════════════════════════════════════
class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final int booksCount;
  final int sheikhsCount;
  final int lessonsCount;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    this.booksCount = 0,
    this.sheikhsCount = 0,
    this.lessonsCount = 0,
  });

  /// إنشاء كائن من خريطة Firestore
  factory CategoryModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return CategoryModel(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'category',
      booksCount: map['booksCount'] as int? ?? 0,
      sheikhsCount: map['sheikhsCount'] as int? ?? 0,
      lessonsCount: map['lessonsCount'] as int? ?? 0,
    );
  }

  /// تحويل الكائن إلى خريطة لحفظها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'booksCount': booksCount,
      'sheikhsCount': sheikhsCount,
      'lessonsCount': lessonsCount,
    };
  }

  /// إنشاء نسخة معدلة من الكائن
  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    int? booksCount,
    int? sheikhsCount,
    int? lessonsCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      booksCount: booksCount ?? this.booksCount,
      sheikhsCount: sheikhsCount ?? this.sheikhsCount,
      lessonsCount: lessonsCount ?? this.lessonsCount,
    );
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

