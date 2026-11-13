import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mock_data_service.dart';
import '../widgets/decorated_header.dart';
import 'lesson_player_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة قائمة دروس الشرح (SeriesLessonsScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// نقطة الالتقاء بين الكتاب والشيخ الشارح، وتتضمن:
/// 1. هيدر بني مزخرف مع زر الرجوع.
/// 2. بطاقة معلومات الشرح، ونسبة الإنجاز والتقدم.
/// 3. زر محوري: "بدء دراسة هذا المتن" (يضيف الشرح للمحفوظات ويحفظه في SharedPreferences).
/// 4. قائمة الدروس المرقمة مع علامة التفريغ النصي ومدة الدرس وحالة الاكتمال.
/// ═══════════════════════════════════════════════════════════════════════════
class SeriesLessonsScreen extends StatelessWidget {
  final SeriesModel series;
  final BookModel? book;
  final SheikhModel? sheikh;

  const SeriesLessonsScreen({
    super.key,
    required this.series,
    this.book,
    this.sheikh,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final actualBook = book ?? appProvider.getBookById(series.bookId) ?? MockDataService.getBookById(series.bookId);
        final actualSheikh = sheikh ?? appProvider.getSheikhById(series.sheikhId) ?? MockDataService.getSheikhById(series.sheikhId);
        final category = appProvider.getCategoryById(series.categoryId) ?? MockDataService.getCategoryById(series.categoryId);
        final lessons = appProvider.getLessonsBySeries(series.id);
        final isStudied = appProvider.isSeriesStudied(series.id);
        final progress = appProvider.getSeriesProgress(series.id);
        final completedInSeries = appProvider.getCompletedLessonsInSeries(series.id);

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر البني العلوي المزخرف مع زر الرجوع ─────────────
              DecoratedHeader(
                title: actualBook?.title ?? series.title,
                showSearchIcon: false,
                actions: [
                  IconButton(
                    tooltip: 'رجوع',
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textGoldLight,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // ── 2. محتوى الشاشة ──────────────────────────────────────────
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    // ── بطاقة تعريف الشرح وزر بدء الدراسة ─────────────────
                    _buildSeriesHeaderCard(
                      context,
                      appProvider: appProvider,
                      actualBook: actualBook,
                      actualSheikh: actualSheikh,
                      category: category,
                      isStudied: isStudied,
                      progress: progress,
                      completedCount: completedInSeries,
                      totalCount: lessons.length,
                    ),

                    const SizedBox(height: 20),

                    // ── عنوان قائمة الدروس ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${lessons.length} درس',
                            style: GoogleFonts.readexPro(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'قائمة الدروس العلمية',
                            style: GoogleFonts.readexPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── قائمة الدروس المرقمة ───────────────────────────────
                    if (lessons.isEmpty)
                      _buildEmptyLessonsState()
                    else
                      ...lessons.map((lesson) {
                        final isCompleted = appProvider.isLessonCompleted(lesson.id);
                        return _buildLessonCard(
                          context,
                          lesson: lesson,
                          isCompleted: isCompleted,
                          appProvider: appProvider,
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// بطاقة معلومات الشرح العلوية
  Widget _buildSeriesHeaderCard(
    BuildContext context, {
    required AppProvider appProvider,
    required BookModel? actualBook,
    required SheikhModel? actualSheikh,
    required CategoryModel? category,
    required bool isStudied,
    required double progress,
    required int completedCount,
    required int totalCount,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // كبسولة القسم
              if (category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldBeige.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category.name,
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

              const Spacer(),

              // اسم الكتاب والشارح
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      actualBook?.title ?? series.title,
                      style: GoogleFonts.readexPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الشارح: ${actualSheikh?.name ?? ""}',
                      style: GoogleFonts.readexPro(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // أيقونة الكتاب
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.iconGold,
                  size: 26,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.dividerLight, height: 1),
          const SizedBox(height: 14),

          // ── شريط نسبة الإنجاز في الشرح ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
              Text(
                'أنجزت $completedCount من $totalCount درساً',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.dividerLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGoldBeige),
            ),
          ),

          const SizedBox(height: 16),

          // ── الزر المحوري: بدء دراسة هذا المتن ───────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                appProvider.toggleStudySeries(series.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isStudied
                          ? 'تمت إزالة المتن من قائمة الدراسة'
                          : 'تمت إضافة المتن إلى المحفوظات (قيد الدراسة)',
                      style: GoogleFonts.readexPro(),
                    ),
                    backgroundColor: AppColors.primaryDarkBrown,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: isStudied
                      ? const Color(0xFF2E7D32)
                      : AppColors.accentGoldBeige,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isStudied
                          ? const Color(0x332E7D32)
                          : AppColors.accentGoldBeige.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isStudied
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_add_outlined,
                      color: isStudied ? Colors.white : AppColors.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isStudied
                          ? 'مضاف في المحفوظات (قيد الدراسة) ✓'
                          : 'بدء دراسة هذا المتن',
                      style: GoogleFonts.readexPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isStudied ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة الدرس المرقمة
  Widget _buildLessonCard(
    BuildContext context, {
    required LessonModel lesson,
    required bool isCompleted,
    required AppProvider appProvider,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? const Color(0x332E7D32)
              : AppColors.dividerLight,
          width: isCompleted ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // تحديث آخر درس مستمع (لا يضيف الشرح لقائمة المحفوظات)
            appProvider.setLastPlayedLesson(lesson);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LessonPlayerScreen(
                  lesson: lesson,
                  series: series,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // زر تعليم الدرس كمكتمل على اليسار في RTL
                IconButton(
                  tooltip: isCompleted ? 'مكتمل' : 'تعليم كمكتمل',
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isCompleted
                        ? const Color(0xFF2E7D32)
                        : AppColors.dividerLight,
                    size: 24,
                  ),
                  onPressed: () {
                    appProvider.toggleLessonCompleted(lesson.id);
                  },
                ),

                const SizedBox(width: 6),

                // سهم أو زر التشغيل
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: AppColors.iconGold,
                  size: 26,
                ),

                const Spacer(),

                // معلومات الدرس
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lesson.title,
                        style: GoogleFonts.readexPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 5),

                      // شارات المعلومات: المدة، التفريغ، الفيديو
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (lesson.hasVideo) ...[
                            _buildFeatureBadge('مرئي', Icons.videocam_rounded),
                            const SizedBox(width: 6),
                          ],
                          if (lesson.hasTranscript) ...[
                            _buildFeatureBadge('مفرغ نصياً', Icons.description_rounded),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            lesson.duration,
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // رقم الدرس داخل دائرة
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFE8F5E9)
                        : AppColors.accentGoldBeige.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF2E7D32)
                          : AppColors.accentGoldBeige,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${lesson.order}',
                      style: GoogleFonts.readexPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? const Color(0xFF2E7D32)
                            : AppColors.primaryDarkBrown,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.scaffoldCream,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.readexPro(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 3),
          Icon(icon, size: 10, color: AppColors.iconGold),
        ],
      ),
    );
  }

  Widget _buildEmptyLessonsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.iconGold),
            const SizedBox(height: 12),
            Text(
              'لا توجد دروس مضافة لهذا الشرح حالياً',
              style: GoogleFonts.readexPro(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

