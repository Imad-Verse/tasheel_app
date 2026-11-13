import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج الإشعارات (AppNotificationModel)
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل إشعاراً مرسلاً للطلاب مع تصنيف النوع، ورابط الإجراء، ووقت الإرسال.
/// متوافق مع Firebase Firestore والتخزين المحلي في SharedPreferences.
/// ═══════════════════════════════════════════════════════════════════════════
class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'general', 'sheikh', 'lesson', 'transcript', 'update'
  final String? actionUrl;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'general',
    this.actionUrl,
    required this.createdAt,
  });

  /// إنشاء كائن من خريطة بيانات Firestore أو JSON
  factory AppNotificationModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parsedDate;
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      parsedDate = rawCreated.toDate();
    } else if (rawCreated is String) {
      parsedDate = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else if (rawCreated is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawCreated);
    } else {
      parsedDate = DateTime.now();
    }

    return AppNotificationModel(
      id: docId ?? map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      actionUrl: map['actionUrl']?.toString(),
      createdAt: parsedDate,
    );
  }

  /// تحويل الكائن إلى خريطة لحفظها في Firestore أو التخزين المحلي
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'actionUrl': actionUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? actionUrl,
    DateTime? createdAt,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

