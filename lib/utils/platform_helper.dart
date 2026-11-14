import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// أداة فحص المنصة الآمنة لجميع البيئات (PlatformHelper)
/// ═══════════════════════════════════════════════════════════════════════════
/// تعتمد حصرياً على `package:flutter/foundation.dart` (`kIsWeb` و `defaultTargetPlatform`)
/// دون أي استدعاء لمكتبة `dart:io` لضمان التوافق التام ومنع انهيار الويب (Web Safe).
/// تدعم: Android, iOS, Windows, macOS, Linux, and Web.
/// ═══════════════════════════════════════════════════════════════════════════
class PlatformHelper {
  const PlatformHelper._();

  /// هل التطبيق يعمل في بيئة المتصفح والويب
  static bool get isWeb => kIsWeb;

  /// هل التطبيق يعمل على الهواتف الذكية (Android أو iOS)
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// هل التطبيق يعمل على أنظمة سطح المكتب (Windows أو macOS أو Linux)
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// هل النظام هو أندرويد حصراً
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// هل النظام هو iOS حصراً
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// هل النظام هو ويندوز حصراً
  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// هل النظام هو ماك حصراً
  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// هل النظام هو لينكس حصراً
  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
}

