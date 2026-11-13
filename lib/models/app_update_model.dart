/// ═══════════════════════════════════════════════════════════════════════════
/// نموذج تحديث التطبيق (AppUpdateModel)
/// ═══════════════════════════════════════════════════════════════════════════
/// يمثل معلومات أحدث إصدار متوفر للتطبيق على السحابة مع رابط التحميل
/// وملاحظات الإصدار وسياسة التحديث (إجباري أم اختياري).
/// ═══════════════════════════════════════════════════════════════════════════
class AppUpdateModel {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isForceUpdate;

  const AppUpdateModel({
    this.latestVersion = '1.0.0',
    this.downloadUrl = '',
    this.releaseNotes = '',
    this.isForceUpdate = false,
  });

  /// إنشاء كائن من خريطة بيانات Firestore أو JSON
  factory AppUpdateModel.fromMap(Map<String, dynamic> map) {
    return AppUpdateModel(
      latestVersion: map['latestVersion']?.toString() ?? '1.0.0',
      downloadUrl: map['downloadUrl']?.toString() ?? '',
      releaseNotes: map['releaseNotes']?.toString() ?? '',
      isForceUpdate: map['isForceUpdate'] == true,
    );
  }

  /// تحويل الكائن إلى خريطة لحفظها في Firestore أو التخزين المحلي
  Map<String, dynamic> toMap() {
    return {
      'latestVersion': latestVersion,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'isForceUpdate': isForceUpdate,
    };
  }

  AppUpdateModel copyWith({
    String? latestVersion,
    String? downloadUrl,
    String? releaseNotes,
    bool? isForceUpdate,
  }) {
    return AppUpdateModel(
      latestVersion: latestVersion ?? this.latestVersion,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      isForceUpdate: isForceUpdate ?? this.isForceUpdate,
    );
  }
}

