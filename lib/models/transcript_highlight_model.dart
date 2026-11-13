/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج تظليل نص التفريغ (TranscriptHighlightModel)
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل تظليلاً علمياً يضعه طالب العلم على عبارة معينة في التفريغ النصي لدرس ما.
/// يحتوي على معرف الدرس، النص المظلل، نطاق البداية والنهاية، واللون.
/// ═══════════════════════════════════════════════════════════════════════════
class TranscriptHighlightModel {
  final String id;
  final String lessonId;
  final String selectedText;
  final int startIndex;
  final int endIndex;
  final String colorHex;
  final DateTime createdAt;

  const TranscriptHighlightModel({
    required this.id,
    required this.lessonId,
    required this.selectedText,
    required this.startIndex,
    required this.endIndex,
    required this.colorHex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'selectedText': selectedText,
      'startIndex': startIndex,
      'endIndex': endIndex,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TranscriptHighlightModel.fromMap(Map<String, dynamic> map) {
    return TranscriptHighlightModel(
      id: map['id'] as String? ?? '',
      lessonId: map['lessonId'] as String? ?? '',
      selectedText: map['selectedText'] as String? ?? '',
      startIndex: (map['startIndex'] as num?)?.toInt() ?? 0,
      endIndex: (map['endIndex'] as num?)?.toInt() ?? 0,
      colorHex: map['colorHex'] as String? ?? '#FFF59D',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  TranscriptHighlightModel copyWith({
    String? id,
    String? lessonId,
    String? selectedText,
    int? startIndex,
    int? endIndex,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return TranscriptHighlightModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      selectedText: selectedText ?? this.selectedText,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'TranscriptHighlightModel(id: $id, lessonId: $lessonId, text: $selectedText, color: $colorHex)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptHighlightModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

