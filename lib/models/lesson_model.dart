/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج الدرس
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل درساً صوتياً أو مرئياً ضمن سلسلة شرح معينة.
/// يحتوي على رابط الصوت والفيديو والتفريغ النصي.
/// جاهز للربط مع Firebase Firestore عبر fromMap و toMap.
/// ═══════════════════════════════════════════════════════════════════════════
class LessonModel {
  final String id;
  final String seriesId;
  final String title;
  final int order;
  final String duration;
  final String audioUrl;
  final String videoUrl;
  final String transcript;

  const LessonModel({
    required this.id,
    required this.seriesId,
    required this.title,
    required this.order,
    this.duration = '00:00',
    this.audioUrl = '',
    this.videoUrl = '',
    this.transcript = '',
  });

  /// هل يوجد تفريغ نصي لهذا الدرس؟
  bool get hasTranscript => transcript.isNotEmpty;

  /// هل يوجد رابط صوتي؟
  bool get hasAudio => audioUrl.isNotEmpty;

  /// هل يوجد رابط فيديو؟
  bool get hasVideo => videoUrl.isNotEmpty;

  /// إنشاء كائن من خريطة Firestore
  factory LessonModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return LessonModel(
      id: docId ?? map['id'] as String? ?? '',
      seriesId: map['seriesId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      order: map['order'] as int? ?? 0,
      duration: map['duration'] as String? ?? '00:00',
      audioUrl: map['audioUrl'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      transcript: map['transcript'] as String? ?? '',
    );
  }

  /// تحويل الكائن إلى خريطة لحفظها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seriesId': seriesId,
      'title': title,
      'order': order,
      'duration': duration,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'transcript': transcript,
    };
  }

  /// إنشاء نسخة معدلة من الكائن
  LessonModel copyWith({
    String? id,
    String? seriesId,
    String? title,
    int? order,
    String? duration,
    String? audioUrl,
    String? videoUrl,
    String? transcript,
  }) {
    return LessonModel(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      title: title ?? this.title,
      order: order ?? this.order,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      transcript: transcript ?? this.transcript,
    );
  }

  @override
  String toString() => 'LessonModel(id: $id, title: $title, order: $order)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

