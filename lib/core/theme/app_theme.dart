import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// تطبيق تسهيل - الثيم العام للتطبيق
/// ═══════════════════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  /// الثيم الرئيسي (الفاتح) للتطبيق
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ─── الألوان الأساسية ──────────────────────────────────────
      primaryColor: AppColors.primaryDarkBrown,
      scaffoldBackgroundColor: AppColors.scaffoldCream,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDarkBrown,
        onPrimary: AppColors.textWhite,
        secondary: AppColors.accentGoldBeige,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.cardWhite,
        onSurface: AppColors.textPrimary,
        error: Color(0xFFB00020),
        onError: AppColors.textWhite,
      ),

      // ─── AppBar ───────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDarkBrown,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.readexPro(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textGoldLight,
        ),
      ),

      // ─── نمط النصوص ──────────────────────────────────────────
      textTheme: _buildTextTheme(),

      // ─── البطاقات ─────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 1,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ─── الأيقونات ────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.iconGold,
        size: 24,
      ),

      // ─── الفواصل ──────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 0,
      ),

      // ─── الأزرار ──────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGoldBeige,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.readexPro(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── حقول الإدخال ────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accentGoldBeige, width: 2),
        ),
        hintStyle: GoogleFonts.readexPro(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      // ─── BottomSheet ─────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ─── BottomNavigationBar ──────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNavBackground,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.inactiveTabIcon,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.readexPro(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.readexPro(fontSize: 12),
        elevation: 8,
      ),
    );
  }

  /// بناء نمط النصوص باستخدام خط Readex Pro للواجهات
  static TextTheme _buildTextTheme() {
    final baseTextTheme = GoogleFonts.readexProTextTheme();

    return baseTextTheme.copyWith(
      // العناوين الكبيرة
      headlineLarge: GoogleFonts.readexPro(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      headlineMedium: GoogleFonts.readexPro(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      headlineSmall: GoogleFonts.readexPro(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ),

      // العناوين المتوسطة
      titleLarge: GoogleFonts.readexPro(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.readexPro(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.readexPro(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      ),

      // نصوص الجسم
      bodyLarge: GoogleFonts.readexPro(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.readexPro(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.readexPro(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      ),

      // التصنيفات والأزرار
      labelLarge: GoogleFonts.readexPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.readexPro(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.readexPro(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// خط أميري للمقولات والآيات والنصوص الشرعية
  static TextStyle get amiriQuoteStyle => GoogleFonts.amiri(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.8,
      );

  /// خط أميري بحجم أكبر للعناوين الرئيسية
  static TextStyle get amiriTitleStyle => GoogleFonts.amiri(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textGoldLight,
        height: 1.5,
      );

  /// خط أميري للشعارات والنصوص الزخرفية
  static TextStyle get amiriDisplayStyle => GoogleFonts.amiri(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.textGoldLight,
        height: 1.3,
      );

  /// نصف قطر الحواف الدائرية القياسي للبطاقات
  static BorderRadius get cardBorderRadius => BorderRadius.circular(16);

  /// نصف قطر الحواف الدائرية الصغير
  static BorderRadius get smallBorderRadius => BorderRadius.circular(12);

  /// ظل البطاقات القياسي
  static List<BoxShadow> get cardBoxShadow => [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];
}

