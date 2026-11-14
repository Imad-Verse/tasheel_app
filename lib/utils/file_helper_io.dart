import 'dart:io';
import 'package:path_provider/path_provider.dart';

// تطبيق أصلي لنظام الملفات للأنظمة الداعمة لـ `dart:io` (الهاتف وسطح المكتب)

/// التحقق من وجود ملف محلي
bool fileExists(String path) {
  try {
    return File(path).existsSync();
  } catch (_) {
    return false;
  }
}

/// قراءة حجم الملف المحلي بالبايت
int getFileSizeSync(String path) {
  try {
    final file = File(path);
    return file.existsSync() ? file.lengthSync() : 0;
  } catch (_) {
    return 0;
  }
}

/// حذف ملف محلي بأمان
Future<void> deleteFileSafely(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}
}

/// جلب مسار مجلد التحميلات للتطبيق وإنشاؤه إن لم يوجد
Future<String?> getAppDownloadDirectoryPath() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final saveDir = Directory('${appDir.path}/tasheel_downloads');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return saveDir.path;
  } catch (_) {
    return null;
  }
}

/// كتابة ملف محلياً
Future<void> writeMockFile(String path, String content) async {
  try {
    final file = File(path);
    await file.writeAsString(content);
  } catch (_) {}
}

