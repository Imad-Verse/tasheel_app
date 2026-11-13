/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج الشيخ / العالم
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل بيانات الشيخ بما فيها النبذة المختصرة والسيرة الكاملة.
/// جاهز للربط مع Firebase Firestore عبر fromMap و toMap.
/// ═══════════════════════════════════════════════════════════════════════════
class SheikhModel {
  final String id;
  final String name;
  final String shortBio;
  final String fullBio;
  final int booksCount;
  final int lessonsCount;

  const SheikhModel({
    required this.id,
    required this.name,
    required this.shortBio,
    this.fullBio = '',
    this.booksCount = 0,
    this.lessonsCount = 0,
  });

  /// إنشاء كائن من خريطة Firestore
  factory SheikhModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return SheikhModel(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      shortBio: map['shortBio'] as String? ?? '',
      fullBio: map['fullBio'] as String? ?? '',
      booksCount: map['booksCount'] as int? ?? 0,
      lessonsCount: map['lessonsCount'] as int? ?? 0,
    );
  }

  /// تحويل الكائن إلى خريطة لحفظها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortBio': shortBio,
      'fullBio': fullBio,
      'booksCount': booksCount,
      'lessonsCount': lessonsCount,
    };
  }

  /// إنشاء نسخة معدلة من الكائن
  SheikhModel copyWith({
    String? id,
    String? name,
    String? shortBio,
    String? fullBio,
    int? booksCount,
    int? lessonsCount,
  }) {
    return SheikhModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortBio: shortBio ?? this.shortBio,
      fullBio: fullBio ?? this.fullBio,
      booksCount: booksCount ?? this.booksCount,
      lessonsCount: lessonsCount ?? this.lessonsCount,
    );
  }

  @override
  String toString() => 'SheikhModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SheikhModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

