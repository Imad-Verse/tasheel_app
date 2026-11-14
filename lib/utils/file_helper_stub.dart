// تطبيق بديل آمن لبيئة الويب بدون أي اعتماد على `dart:io`

/// التحقق من وجود ملف محلي
bool fileExists(String path) => false;

/// قراءة حجم الملف المحلي بالبايت
int getFileSizeSync(String path) => 0;

/// حذف ملف محلي بأمان
Future<void> deleteFileSafely(String path) async {}

/// جلب مسار مجلد التحميلات للتطبيق
Future<String?> getAppDownloadDirectoryPath() async => null;

/// كتابة ملف تجريبي محلياً
Future<void> writeMockFile(String path, String content) async {}
