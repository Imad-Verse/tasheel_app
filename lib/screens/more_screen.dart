import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../config/app_flavor.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_provider.dart';
import 'about_app_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'downloads_screen.dart';
import 'notes_notebook_screen.dart';
import 'playlists_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'storage_manager_screen.dart';

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
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final rawPhone = appProvider.aboutApp.supportWhatsapp;
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    const message = 'السلام عليكم اراسلك من تطبيق تسهيل للعلوم الشرعية احتاج للتحدث معكم';
    final encoded = Uri.encodeComponent(message);
    final waUri = cleanPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$cleanPhone?text=$encoded')
        : Uri.parse('https://wa.me/?text=$encoded');

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
  void _shareApp(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final aboutApp = appProvider.aboutApp;
    final shareText = '${aboutApp.shareDescription}\n${aboutApp.shareUrl}'.trim();
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

                      // ── بطاقة ويدجت الشاشة الرئيسية (Home Widgets) ────────
                      _buildHomeWidgetsCard(context, appProvider),

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
                      if (kIsAdminBuild)
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'تطبيق تسهيل للعلوم الشرعية • الإصدار ${appProvider.currentAppVersion}',
                              style: GoogleFonts.readexPro(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDarkBrown,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.iconGold,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryDarkBrown.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                '(نسخة الإدارة - Admin)',
                                style: GoogleFonts.readexPro(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textGoldLight,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'تطبيق تسهيل للعلوم الشرعية • الإصدار ${appProvider.currentAppVersion}',
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

  /// البطاقة البيضاء الأولى: لوحة التحكم (نسخة الإدارة فقط)، المحفوظات، التنزيلات، الإعدادات، الإحصائيات
  Widget _buildFirstMenuCard(BuildContext context, AppProvider appProvider) {
    return _buildCardWrapper([
      if (kIsAdminBuild)
        _MenuItemData(
          title: 'لوحة التحكم والإدارة',
          icon: Icons.admin_panel_settings_rounded,
          badgeText: 'Admin',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          },
        ),
      _MenuItemData(
        title: 'المحفوظات',
        icon: Icons.bookmark_outline_rounded,
        onTap: () {
          // الانتقال لتبويب المحفوظات (الفهرس 3)
          appProvider.setCurrentTab(3);
        },
      ),
      _MenuItemData(
        title: 'قوائم التشغيل والمجموعات',
        icon: Icons.featured_play_list_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
          );
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
        title: 'إدارة المساحة التخزينية',
        icon: Icons.pie_chart_outline_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StorageManagerScreen()),
          );
        },
      ),
      _MenuItemData(
        title: 'كناشة الفوائد',
        icon: Icons.edit_note_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotesNotebookScreen()),
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

  /// بطاقة وتوجيهات ويدجت الشاشة الرئيسية للهاتف (Home Screen Widgets)
  Widget _buildHomeWidgetsCard(BuildContext context, AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkBrown.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.iconGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.widgets_rounded,
                  color: AppColors.primaryDarkBrown,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ويدجت الشاشة الرئيسية',
                          style: GoogleFonts.readexPro(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.iconGold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'جديد',
                            style: GoogleFonts.readexPro(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDarkBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'استأنف الدرس، واقرأ الفوائد، وتابع إنجازك من شاشة هاتفك',
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // زر شرح طريقة الإضافة
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showWidgetInstructionsSheet(context),
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: Text(
                    'طريقة الإضافة',
                    style: GoogleFonts.readexPro(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDarkBrown,
                    side: const BorderSide(color: AppColors.iconGold),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // زر الاختبار والتحديث اللحظي
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await appProvider.updateHomeWidgets();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم تحديث بيانات الويدجت في الشاشة الرئيسية بنجاح ✨',
                            style: GoogleFonts.readexPro(),
                          ),
                          backgroundColor: AppColors.primaryDarkBrown,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: Text(
                    'تحديث الآن',
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkBrown,
                    foregroundColor: AppColors.textGoldLight,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// نافذة توضيح كيفية إضافة الويدجت لشاشة الهاتف الرئيسية
  void _showWidgetInstructionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.widgets_rounded,
                  color: AppColors.iconGold,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'كيفية إضافة ويدجت "تسهيل" لشاشتك الرئيسية',
                  style: GoogleFonts.readexPro(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarkBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStepItem(
              number: '١',
              title: 'الضغط المطول',
              desc: 'اضغط مطولاً على أي مساحة فارغة في شاشة هاتفك الرئيسية.',
            ),
            const SizedBox(height: 12),
            _buildStepItem(
              number: '٢',
              title: 'اختيار التطبيقات المصغرة',
              desc: 'انقر على "التطبيقات المصغرة" أو "Widgets" من الخيارات الظاهرة.',
            ),
            const SizedBox(height: 12),
            _buildStepItem(
              number: '٣',
              title: 'اختيار ويدجت تسهيل',
              desc: 'ابحث عن "تسهيل"، واختر الويدجت المطلوب (استئناف المدارسة، فائدة مختارة، أو مؤشر الإنجاز) واسحبه للشاشة.',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkBrown,
                foregroundColor: AppColors.textGoldLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'فهمت ذلك',
                style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryDarkBrown,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.iconGold, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.readexPro(
              color: AppColors.textGoldLight,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        onTap: () => _shareApp(context),
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

                        // النص في اليمين مع شارة اختيارية
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.badgeText != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDarkBrown,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.iconGold,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  item.badgeText!,
                                  style: GoogleFonts.readexPro(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textGoldLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              item.title,
                              style: GoogleFonts.readexPro(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
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
  final String? badgeText;

  const _MenuItemData({
    required this.title,
    required this.icon,
    required this.onTap,
    this.badgeText,
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
