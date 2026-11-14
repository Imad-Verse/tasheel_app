// تصدير نظام الملفات الآمن تلقائياً بحسب بيئة التشغيل
// في بيئة الويب: يتم استخدام file_helper_stub.dart لمنع أي استدعاء لـ dart:io
// في بيئات الهاتف وسطح المكتب: يتم استخدام file_helper_io.dart للتعامل مع الملفات المحلية
export 'file_helper_stub.dart'
    if (dart.library.io) 'file_helper_io.dart';
