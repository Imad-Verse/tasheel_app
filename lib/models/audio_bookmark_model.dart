/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج الفاصل الصوتي / العلامة المرجعية (AudioBookmarkModel)
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل إشارة مرجعية يضعها طالب العلم عند موضع زمني محدد في الدرس الصوتي
/// مع إمكانية تسميتها وتلوينها للتنقل المباشر إليها.
/// ═══════════════════════════════════════════════════════════════════════════
class AudioBookmarkModel {
  final String id;
  final String lessonId;
  final int positionSeconds;
  final String? label;
  final String colorHex;
  final DateTime createdAt;

  const AudioBookmarkModel({
    required this.id,
    required this.lessonId,
    required this.positionSeconds,
    this.label,
    this.colorHex = '#D4AF37',
    required this.createdAt,
  });

  /// التنسيق الزمني للفاصل (مثال: 05:20 أو 01:15:30)
  String get formattedTimestamp {
    final minutes = (positionSeconds ~/ 60).remainder(60).toString().padLeft(2, '0');
    final seconds = (positionSeconds % 60).toString().padLeft(2, '0');
    final hours = positionSeconds ~/ 3600;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'positionSeconds': positionSeconds,
      if (label != null && label!.trim().isNotEmpty) 'label': label!.trim(),
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AudioBookmarkModel.fromMap(Map<String, dynamic> map) {
    return AudioBookmarkModel(
      id: map['id'] as String? ?? '',
      lessonId: map['lessonId'] as String? ?? '',
      positionSeconds: (map['positionSeconds'] as num?)?.toInt() ?? 0,
      label: map['label'] as String?,
      colorHex: map['colorHex'] as String? ?? '#D4AF37',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AudioBookmarkModel copyWith({
    String? id,
    String? lessonId,
    int? positionSeconds,
    String? label,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return AudioBookmarkModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      label: label ?? this.label,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'AudioBookmarkModel(id: $id, lessonId: $lessonId, at: $formattedTimestamp, label: $label)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioBookmarkModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

