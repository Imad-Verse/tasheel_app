import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// تطبيق تسهيل - الألوان الرسمية للهوية البصرية
/// ═══════════════════════════════════════════════════════════════════════════
/// جميع الألوان مستخرجة من التصاميم المرجعية المعتمدة.
/// يُمنع استخدام أي ألوان خارج هذا الملف في واجهات التطبيق.
/// ═══════════════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._(); // منع إنشاء كائنات من هذه الفئة

  // ─── الألوان الأساسية ─────────────────────────────────────────────────────

  /// اللون البني الداكن الرئيسي - يُستخدم في الهيدر العلوي وشاشة البداية
  static const Color primaryDarkBrown = Color(0xFF4A3B32);

  /// لون الزخرفة الهندسية الخفيفة داخل الهيدر وشاشة البداية
  static const Color patternBrown = Color(0xFF3E3028);

  /// لون البني الفاتح الثانوي
  static const Color primaryLightBrown = Color(0xFF5D4A3E);

  /// لون الخلفية الكريمي الفاتح والمريح للعين
  static const Color scaffoldCream = Color(0xFFF9F6F0);

  /// لون البطاقات البيضاء
  static const Color cardWhite = Color(0xFFFFFFFF);

  // ─── ألوان التمييز والتفاعل ──────────────────────────────────────────────

  /// اللون البيج/الذهبي الهادئ - للتبويب النشط والأزرار البارزة
  static const Color accentGoldBeige = Color(0xFFDEC89E);

  /// لون الأيقونات الذهبية داخل البطاقات
  static const Color iconGold = Color(0xFFC8AD7F);

  /// لون ذهبي خافت للحدود
  static const Color goldMuted = Color(0xFFC8AD7F);

  /// لون ذهبي فاتح
  static const Color goldLight = Color(0xFFDEC89E);

  // ─── ألوان النصوص ────────────────────────────────────────────────────────

  /// لون النصوص الرئيسية البني الداكن جداً
  static const Color textPrimary = Color(0xFF2D231E);

  /// لون النصوص الفرعية والأرقام الرمادي الدافئ
  static const Color textSecondary = Color(0xFF8C7A6B);

  // ─── ألوان مساعدة ────────────────────────────────────────────────────────

  /// لون الفواصل والحدود الخفيفة
  static const Color dividerLight = Color(0xFFE8E0D5);

  /// لون خلفية البطاقات الثانوية (مثل بطاقات الإحصائيات)
  static const Color cardCreamLight = Color(0xFFF5F0E8);

  /// لون الظل الخفيف للبطاقات
  static const Color cardShadow = Color(0x0D000000); // أسود بشفافية 5%

  /// لون النص الأبيض (للنصوص فوق الخلفيات الداكنة)
  static const Color textWhite = Color(0xFFFFFFFF);

  /// لون النص الذهبي الفاتح (للنصوص فوق الخلفيات البنية)
  static const Color textGoldLight = Color(0xFFDEC89E);

  /// لون شريط التنقل السفلي
  static const Color bottomNavBackground = Color(0xFFFFFFFF);

  /// لون أيقونة التبويب غير النشط
  static const Color inactiveTabIcon = Color(0xFF8C7A6B);
}

