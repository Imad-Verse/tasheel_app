import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../core/theme/app_colors.dart';
import '../providers/app_provider.dart';
import 'about_app_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة المزيد (MoreScreen) - مطابقة للصورة المرجعية
/// ═══════════════════════════════════════════════════════════════════════════
/// تتضمن:
/// 1. هيدر الحساب العلوي المزخرف مع اسم طالب العلم وزر كبسولة "إعدادات الحساب".
/// 2. البطاقة البيضاء الأولى (المحفوظات، التنزيلات، الإعدادات، الإحصائيات).
/// 3. البطاقة البيضاء الثانية (عن التطبيق، تقييم التطبيق، شارك التطبيق، الدعم الفني).
/// ═══════════════════════════════════════════════════════════════════════════
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  /// فتح واتساب للدعم الفني
  Future<void> _openWhatsAppSupport(BuildContext context) async {
    const message = 'السلام عليكم اراسلك من تطبيق تسهيل للعلوم الشرعية احتاج للتحدث معكم';
    final encoded = Uri.encodeComponent(message);
    final waUri = Uri.parse('https://wa.me/?text=$encoded');

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUri);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح تطبيق واتساب مباشرة.',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: AppColors.primaryDarkBrown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// فتح تقييم التطبيق على متجر Google Play
  Future<void> _rateApp(BuildContext context) async {
    final playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=com.tasheel.tasheel_app');
    try {
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// مشاركة التطبيق عبر وسائل التواصل الاجتماعي
  void _shareApp() {
    const shareText =
        'تطبيق (تسهيل) طريقك لتيسير العلوم الشرعية.. استمع لشروحات المتون العلمية لكبار العلماء مع التفريغات النصية وميزة الاستماع بدون إنترنت. حمله الآن: https://madoverse.site/tasheel';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. هيدر الحساب العلوي المزخرف (مطابق للصورة المرجعية) ──
              _buildProfileHeader(context, appProvider),

              // ── 2. محتوى القوائم ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
                  child: Column(
                    children: [
                      // ── البطاقة البيضاء الأولى (4 عناصر) ─────────────────
                      _buildFirstMenuCard(context, appProvider),

                      const SizedBox(height: 16),

                      // ── البطاقة البيضاء الثانية (4 عناصر) ────────────────
                      _buildSecondMenuCard(context),

                      const SizedBox(height: 18),

                      // حقوق وتذييل الصفحة مع شعار التطبيق
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accentGoldBeige,
                            width: 1.2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تطبيق تسهيل للعلوم الشرعية • الإصدار 1.0.0',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// هيدر الملف الشخصي البني المزخرف
  Widget _buildProfileHeader(BuildContext context, AppProvider appProvider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDarkBrown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // خلفية الزخرفة الإسلامية
          Positioned.fill(
            child: CustomPaint(
              painter: _MoreHeaderPatternPainter(),
            ),
          ),
          // صف الصورة والاسم
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // اسم طالب العلم
              Text(
                appProvider.userName,
                style: GoogleFonts.readexPro(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(width: 14),

              // أيقونة المستخدم (خالية من صور ذوات الأرواح تماماً)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.patternBrown.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textGoldLight.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.textGoldLight,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// البطاقة البيضاء الأولى: المحفوظات، التنزيلات، الإعدادات، الإحصائيات
  Widget _buildFirstMenuCard(BuildContext context, AppProvider appProvider) {
    return _buildCardWrapper([
      _MenuItemData(
        title: 'المحفوظات',
        icon: Icons.bookmark_outline_rounded,
        onTap: () {
          // الانتقال لتبويب المحفوظات (الفهرس 3)
          appProvider.setCurrentTab(3);
        },
      ),
      _MenuItemData(
        title: 'التنزيلات',
        icon: Icons.download_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DownloadsScreen()),
          );
        },
      ),
      _MenuItemData(
        title: 'الإعدادات',
        icon: Icons.settings_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      _MenuItemData(
        title: 'الإحصائيات',
        icon: Icons.bar_chart_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()),
          );
        },
      ),
    ]);
  }

  /// البطاقة البيضاء الثانية: عن التطبيق، تقييم التطبيق، شارك التطبيق، الدعم الفني
  Widget _buildSecondMenuCard(BuildContext context) {
    return _buildCardWrapper([
      _MenuItemData(
        title: 'عن التطبيق',
        icon: Icons.auto_stories_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutAppScreen()),
          );
        },
      ),
      _MenuItemData(
        title: 'تقييم التطبيق',
        icon: Icons.star_outline_rounded,
        onTap: () => _rateApp(context),
      ),
      _MenuItemData(
        title: 'شارك التطبيق',
        icon: Icons.share_rounded,
        onTap: _shareApp,
      ),
      _MenuItemData(
        title: 'الدعم الفني',
        icon: Icons.support_agent_rounded,
        onTap: () => _openWhatsAppSupport(context),
      ),
    ]);
  }

  /// غلاف البطاقة البيضاء الجامعة للعناصر
  Widget _buildCardWrapper(List<_MenuItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(16) : Radius.zero,
                    bottom: isLast ? const Radius.circular(16) : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      children: [
                        // سهم التنقل على اليسار في RTL
                        const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.iconGold,
                          size: 22,
                        ),
                        const Spacer(),

                        // النص في اليمين
                        Text(
                          item.title,
                          style: GoogleFonts.readexPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // الأيقونة الذهبية
                        Icon(
                          item.icon,
                          color: AppColors.iconGold,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.dividerLight,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// بيانات عنصر القائمة
class _MenuItemData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

/// رسام زخرفة الهيدر الإسلامية
class _MoreHeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.patternBrown.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 36.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        final path = Path();
        path.moveTo(x + spacing / 2, y);
        path.lineTo(x + spacing, y + spacing / 2);
        path.lineTo(x + spacing / 2, y + spacing);
        path.lineTo(x, y + spacing / 2);
        path.close();
        canvas.drawPath(path, paint);

        canvas.save();
        canvas.translate(x + spacing / 2, y + spacing / 2);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: spacing * 0.45,
            height: spacing * 0.45,
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
