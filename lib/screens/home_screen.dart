import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../core/theme/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/global_search_delegate.dart';
import 'lesson_player_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// الشاشة الرئيسية (HomeScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// مطابقة تماماً للصورة المرجعية:
/// 1. هيدر بني داكن مزخرف مع زر الجرس وزر البحث والترحيب.
/// 2. بطاقة "درر السلف" المتداخلة مع خلفية الهيدر.
/// 3. بطاقة "أكمل الاستماع" بديل بطاقة الورد اليومي مع الدرس الأخير.
/// 4. بطاقة "المحفوظات" مع رابط سريع للتبويب.
/// 5. بطاقة "إحصائيات الإنجاز" بالمربعات الثلاثة.
/// ═══════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 140.0;

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final quote = appProvider.currentQuote;
        final lastLesson = appProvider.lastPlayedLesson;
        final lastSeries = appProvider.lastPlayedSeries;

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Stack(
            children: [
              // ── 1. خلفية الهيدر البني الداكن المزخرف في الأعلى ─────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: headerHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDarkBrown,
                  ),
                  child: CustomPaint(
                    painter: _HomeHeaderPatternPainter(),
                  ),
                ),
              ),

              // ── 2. المحتوى القابل للتمرير ────────────────────────────────
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── شريط الهيدر العلوي (الترحيب + الأزرار) ─────────
                      _buildTopBar(context),

                      const SizedBox(height: 18),

                      // ── بطاقة درر السلف (المتداخلة مع الهيدر) ───────────
                      _buildQuoteCard(context, quote, appProvider),

                      const SizedBox(height: 16),

                      // ── بطاقة أكمل الاستماع ──────────────────────────────
                      _buildContinueListeningCard(
                        context,
                        seriesTitle: lastSeries?.title ?? 'شرح كتاب التوحيد',
                        lessonTitle: lastLesson?.title ?? 'الدرس الأول',
                        onTap: () {
                          if (lastLesson != null && lastSeries != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LessonPlayerScreen(
                                  lesson: lastLesson,
                                  series: lastSeries,
                                ),
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // ── بطاقة المحفوظات ──────────────────────────────────
                      _buildBookmarksCard(
                        context,
                        studiedCount: appProvider.studiedSeriesCount,
                        onTap: () {
                          // الانتقال المباشر لتبويب المحفوظات (الفهرس 3)
                          appProvider.setCurrentTab(3);
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── بطاقة إحصائيات الإنجاز ───────────────────────────
                      _buildStatsCard(appProvider),
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

  /// شريط الهيدر العلوي: الأزرار على اليسار والترحيب على اليمين
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // أزرار الإجراءات على اليسار في RTL (البحث والإشعارات)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderCircleButton(
                icon: Icons.search_rounded,
                tooltip: 'البحث الشامل',
                onTap: () => GlobalSearchDelegate.show(context),
              ),
              const SizedBox(width: 8),
              _buildHeaderCircleButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'التنبيهات',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'لا توجد إشعارات جديدة حالياً',
                        style: GoogleFonts.readexPro(),
                      ),
                      backgroundColor: AppColors.primaryDarkBrown,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),

          // النص الترحيبي على اليمين في RTL
          Text(
            'مرحبًا، يا طالب العلم',
            style: GoogleFonts.readexPro(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  /// زر دائري أنيق للهيدر
  Widget _buildHeaderCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.patternBrown.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textGoldLight.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.textGoldLight,
            size: 22,
          ),
        ),
      ),
    );
  }

  /// بطاقة "درر السلف" المتداخلة مع الهيدر
  Widget _buildQuoteCard(
    BuildContext context,
    Map<String, String> quote,
    AppProvider appProvider,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          appProvider.nextQuote();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // علامة الاقتباس العلوية على اليسار (أو اليمين حسب التصميم)
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  '❝',
                  style: GoogleFonts.amiri(
                    fontSize: 32,
                    color: AppColors.accentGoldBeige,
                    height: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // نص المقولة بخط أميري أنيق وواضح
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  quote['text'] ?? '',
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // علامة الاقتباس السفلية
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '❞',
                  style: GoogleFonts.amiri(
                    fontSize: 32,
                    color: AppColors.accentGoldBeige,
                    height: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // اسم القائل مع خطوط ذهبية ناعمة
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 1.2,
                    color: AppColors.accentGoldBeige,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    quote['author'] ?? '',
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.iconGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 1.2,
                    color: AppColors.accentGoldBeige,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة "أكمل الاستماع"
  Widget _buildContinueListeningCard(
    BuildContext context, {
    required String seriesTitle,
    required String lessonTitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // سهم التنقل في أقصى اليسار
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.iconGold,
                size: 24,
              ),

              const Spacer(),

              // النصوص التوضيحية
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'أكمل الاستماع',
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$seriesTitle - $lessonTitle',
                      style: GoogleFonts.readexPro(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // الدائرة الذهبية الفاتحة والأيقونة
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.headphones_rounded,
                  color: AppColors.iconGold,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة "المحفوظات"
  Widget _buildBookmarksCard(
    BuildContext context, {
    required int studiedCount,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // سهم التنقل
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.iconGold,
                size: 24,
              ),

              const Spacer(),

              // النصوص
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'المحفوظات',
                    style: GoogleFonts.readexPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'بدأت دراسة $studiedCount متون',
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // الدائرة والأيقونة
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.iconGold,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة "إحصائيات الإنجاز" بالمربعات الثلاثة
  Widget _buildStatsCard(AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'إحصائيات الإنجاز',
            style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox(
                number: '${appProvider.completedLessonsCount}',
                label: 'درس مكتمل',
              ),
              const SizedBox(width: 10),
              _buildStatBox(
                number: '${appProvider.completedSeriesCount}',
                label: 'متن منجز',
              ),
              const SizedBox(width: 10),
              _buildStatBox(
                number: '${appProvider.listeningHours}',
                label: 'ساعة استماع',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String number,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.scaffoldCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.dividerLight.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: GoogleFonts.readexPro(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.readexPro(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// رسام زخرفة الهيدر العلوي
class _HomeHeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.patternBrown.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const spacing = 26.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawStar(canvas, Offset(x, y), spacing / 2, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(c.dx + r * 0.3 * math.cos(a), c.dy + r * 0.3 * math.sin(a)),
        Offset(c.dx + r * 0.65 * math.cos(a), c.dy + r * 0.65 * math.sin(a)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
