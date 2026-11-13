import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_provider.dart';
import '../services/mock_data_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة الإحصائيات الرسومية الشاملة (StatisticsScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تعرض إحصائيات مكتبة التطبيق ومخططاً دائرياً (Donut Chart) لتوزيع الدروس
/// بالإضافة لإحصائيات إنجاز الطالب ودائرة التقدم المئوية.
/// ═══════════════════════════════════════════════════════════════════════════
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final totalSheikhs = appProvider.sheikhs.isNotEmpty
            ? appProvider.sheikhs.length
            : MockDataService.sheikhs.length;
        final totalBooks = appProvider.books.isNotEmpty
            ? appProvider.books.length
            : MockDataService.books.length;
        final totalSeries = appProvider.series.isNotEmpty
            ? appProvider.series.length
            : MockDataService.series.length;
        final totalLessons = appProvider.lessons.isNotEmpty
            ? appProvider.lessons.length
            : MockDataService.lessons.length;

        final completedLessons = appProvider.completedLessonsCount;
        final studiedSeries = appProvider.studiedSeriesCount;
        final listeningHours = appProvider.listeningHours;
        final overallProgress = totalLessons > 0
            ? (completedLessons / totalLessons).clamp(0.0, 1.0)
            : 0.0;

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر العلوي المزخرف ─────────────────────────────────
              _buildHeader(context),

              // ── 2. المحتوى الإحصائي ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── إحصائيات إنجاز الطالب ───────────────────────────
                      _buildStudentAchievementCard(
                        completedLessons: completedLessons,
                        studiedSeries: studiedSeries,
                        listeningHours: listeningHours,
                        progress: overallProgress,
                      ),

                      const SizedBox(height: 18),

                      // ── إحصائيات مكتبة التطبيق ───────────────────────────
                      _buildLibrarySummaryGrid(
                        sheikhs: totalSheikhs,
                        books: totalBooks,
                        series: totalSeries,
                        lessons: totalLessons,
                      ),

                      const SizedBox(height: 18),

                      // ── توزيع الدروس على الأقسام (Donut Chart) ───────────
                      _buildCategoriesDonutChartCard(),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 12,
        right: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDarkBrown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(
            child: Text(
              'الإحصائيات والإنجاز',
              style: GoogleFonts.readexPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            tooltip: 'رجوع',
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textGoldLight,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// ── 1. بطاقة إنجاز الطالب مع دائرة التقدم الكبيرة ───────────────────────
  Widget _buildStudentAchievementCard({
    required int completedLessons,
    required int studiedSeries,
    required int listeningHours,
    required double progress,
  }) {
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'المسار العلمي',
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDarkBrown,
                  ),
                ),
              ),
              Text(
                'إحصائيات إنجازك',
                style: GoogleFonts.readexPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // دائرة التقدم الكبيرة
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _AchievementRingPainter(
                    progress: progress,
                    trackColor: AppColors.scaffoldCream,
                    progressColor: AppColors.primaryDarkBrown,
                    accentColor: AppColors.accentGoldBeige,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: GoogleFonts.readexPro(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                    Text(
                      'نسبة الإنجاز',
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // المقاييس الثلاثة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAchievementMetric(
                icon: Icons.check_circle_outline_rounded,
                value: '$completedLessons',
                label: 'درس مكتمل',
              ),
              Container(width: 1, height: 36, color: AppColors.dividerLight),
              _buildAchievementMetric(
                icon: Icons.bookmark_added_rounded,
                value: '$studiedSeries',
                label: 'متن قيد الدراسة',
              ),
              Container(width: 1, height: 36, color: AppColors.dividerLight),
              _buildAchievementMetric(
                icon: Icons.access_time_rounded,
                value: '$listeningHours',
                label: 'ساعات استماع',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.iconGold, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.readexPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDarkBrown,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.readexPro(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// ── 2. شبكة إحصائيات مكتبة التطبيق الشاملة ─────────────────────────────
  Widget _buildLibrarySummaryGrid({
    required int sheikhs,
    required int books,
    required int series,
    required int lessons,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'مكتبة تطبيق تسهيل',
          style: GoogleFonts.readexPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDarkBrown,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'الشيوخ والعلماء',
                count: '$sheikhs',
                icon: Icons.person_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                title: 'الكتب والمتون',
                count: '$books',
                icon: Icons.menu_book_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'الشروحات المسجلة',
                count: '$series',
                icon: Icons.auto_stories_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                title: 'الدروس الصوتية',
                count: '$lessons',
                icon: Icons.audiotrack_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.iconGold, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count,
                style: GoogleFonts.readexPro(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.readexPro(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ── 3. بطاقة الرسم الدائري لتوزيع الدروس على الأقسام (Donut Chart) ──────
  Widget _buildCategoriesDonutChartCard() {
    final categories = MockDataService.categories;
    final totalLessons = MockDataService.lessons.length;

    // ألوان ترابية وإسلامية متناسقة للأقسام
    final colors = [
      const Color(0xFF4A3B32), // بني داكن
      const Color(0xFFC8AD7F), // ذهبي ترابي
      const Color(0xFF8C7A6B), // بني فاتح
      const Color(0xFFDEC89E), // بيج ذهبي
      const Color(0xFF6B584B), // موكا
      const Color(0xFFDEC085), // رملي
    ];

    final slices = <_ChartSlice>[];
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final count = cat.lessonsCount;
      slices.add(_ChartSlice(
        label: cat.name,
        value: count,
        color: colors[i % colors.length],
      ));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldCream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.dividerLight),
                ),
                child: Text(
                  '$totalLessons درس',
                  style: GoogleFonts.readexPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iconGold,
                  ),
                ),
              ),
              Text(
                'توزيع الدروس حسب الأقسام',
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // المخطط الدائري Donut Chart في المنتصف
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(170, 170),
                    painter: _DonutChartPainter(slices: slices),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${categories.length}',
                        style: GoogleFonts.readexPro(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDarkBrown,
                        ),
                      ),
                      Text(
                        'أقسام علمية',
                        style: GoogleFonts.readexPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // دليل الأقسام والنسب (Legend)
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: slices.map((s) {
              final pct = totalLessons > 0 ? ((s.value / totalLessons) * 100).round() : 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldCream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.dividerLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct%',
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.label,
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// ─── شريحة من شرائح الرسم الدائري ──────────────────────────────────────────
class _ChartSlice {
  final String label;
  final int value;
  final Color color;

  const _ChartSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// ─── الرسام الخاص بالمخطط الدائري Donut Chart ──────────────────────────────
class _DonutChartPainter extends CustomPainter {
  final List<_ChartSlice> slices;

  _DonutChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 22.0;

    final total = slices.fold<int>(0, (sum, s) => sum + s.value);
    if (total == 0) return;

    var startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

/// ─── الرسام الخاص بحلقة الإنجاز الكبيرة ────────────────────────────────────
class _AchievementRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color accentColor;

  _AchievementRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 14.0;

    // رسم مسار الخلفية
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // رسم قوس التقدم
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = progress.clamp(0.0, 1.0) * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AchievementRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

