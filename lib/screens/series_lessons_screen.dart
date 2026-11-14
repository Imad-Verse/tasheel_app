import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/audio_provider.dart';
import '../services/mock_data_service.dart';
import '../utils/platform_helper.dart';
import '../widgets/decorated_header.dart';
import 'lesson_player_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة قائمة دروس الشرح (SeriesLessonsScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// مضبوطة بالكامل باتجاه اليمين إلى اليسار (RTL):
/// 1. هيدر بني مزخرف مع زر الرجوع في أقصى اليمين (RTL) بسهم موجه لليمين.
/// 2. بطاقة معلومات الشرح، ونسبة الإنجاز والتقدم من اليمين لليسار.
/// 3. زر محوري: "بدء دراسة هذا المتن" (يضيف الشرح للمحفوظات).
/// 4. قائمة الدروس المرقمة: رقم الدرس في أقصى اليمين، العنوان والبيانات بمحاذاة اليمين،
///    وأزرار التشغيل والتعليم كمكتمل في أقصى اليسار.
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
    return Consumer2<AppProvider, AudioProvider>(
      builder: (context, appProvider, audioProvider, child) {
        final actualBook =
            book ??
            appProvider.getBookById(series.bookId) ??
            MockDataService.getBookById(series.bookId);
        final actualSheikh =
            sheikh ??
            appProvider.getSheikhById(series.sheikhId) ??
            MockDataService.getSheikhById(series.sheikhId);
        final category =
            appProvider.getCategoryById(series.categoryId) ??
            MockDataService.getCategoryById(series.categoryId);
        final lessons = appProvider.getLessonsBySeries(series.id);
        final isStudied = appProvider.isSeriesStudied(series.id);
        final progress = appProvider.getSeriesProgress(series.id);
        final completedInSeries = appProvider.getCompletedLessonsInSeries(
          series.id,
        );

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                children: [
                  // ── 1. الهيدر البني العلوي المزخرف مع زر الرجوع على اليمين في RTL ──
                  DecoratedHeader(
                    title: actualBook?.title ?? series.title,
                    showSearchIcon: false,
                    onBackPressed: () => Navigator.pop(context),
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
                          audioProvider: audioProvider,
                          series: series,
                          lessons: lessons,
                          actualBook: actualBook,
                          actualSheikh: actualSheikh,
                          category: category,
                          isStudied: isStudied,
                          progress: progress,
                          completedCount: completedInSeries,
                          totalCount: lessons.length,
                        ),

                        const SizedBox(height: 20),

                        // ── عنوان قائمة الدروس (عنوان يمين، عدد يسار) ───────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // عنوان القائمة على اليمين في RTL
                              Text(
                                'قائمة الدروس العلمية',
                                style: GoogleFonts.readexPro(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),

                              // عدد الدروس على اليسار في RTL
                              Text(
                                '${lessons.length} درس',
                                style: GoogleFonts.readexPro(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
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
                            final isCompleted = appProvider.isLessonCompleted(
                              lesson.id,
                            );
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
            ),
          ),
        );
      },
    );
  }

  /// بطاقة معلومات الشرح العلوية
  Widget _buildSeriesHeaderCard(
    BuildContext context, {
    required AppProvider appProvider,
    required AudioProvider audioProvider,
    required SeriesModel series,
    required List<LessonModel> lessons,
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
              // ── 1. أيقونة الكتاب على اليمين في RTL ──────────────────────
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

              const SizedBox(width: 12),

              // ── 2. اسم الكتاب والشارح بمحاذاة اليمين ─────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // في RTL يبدأ من اليمين
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

              const SizedBox(width: 8),

              // ── 3. كبسولة القسم على اليسار في RTL ───────────────────────
              if (category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldBeige.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category.name,
                    style: GoogleFonts.readexPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.dividerLight, height: 1),
          const SizedBox(height: 14),

          // ── شريط نسبة الإنجاز في الشرح (نص يمين، نسبة يسار) ─────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أنجزت $completedCount من $totalCount درساً',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentGoldBeige,
              ),
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

          const SizedBox(height: 10),

          // ── زر التحميل الجماعي للشرح كاملاً ───────────────────────
          _buildBulkDownloadButton(
            context,
            series: series,
            lessons: lessons,
            audioProvider: audioProvider,
          ),
        ],
      ),
    );
  }

  /// زر وشريط التحميل الجماعي لكامل دروس الشرح
  Widget _buildBulkDownloadButton(
    BuildContext context, {
    required SeriesModel series,
    required List<LessonModel> lessons,
    required AudioProvider audioProvider,
  }) {
    if (lessons.isEmpty) return const SizedBox.shrink();

    final isDownloading = audioProvider.isDownloadingSeries(series.id);
    final isAllDownloaded = audioProvider.isSeriesFullyDownloaded(lessons);
    final undownloadedCount = lessons
        .where((l) => !audioProvider.isDownloaded(l.id))
        .length;

    // 1. حالة الشرح قيد التحميل بالتتابع حالياً
    if (isDownloading) {
      final current = audioProvider.bulkCurrent;
      final total = audioProvider.bulkTotal;
      final progress = audioProvider.bulkDownloadProgress;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.scaffoldCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accentGoldBeige),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryDarkBrown,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'جاري تحميل الشرح: درس ${current + 1} من $total (${(progress * 100).toInt()}%)',
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDarkBrown,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => audioProvider.cancelBulkDownload(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.dividerLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryDarkBrown,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. حالة اكتمال تحميل جميع دروس الشرح على الهاتف
    if (isAllDownloaded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E7D32),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'تم تحميل الشرح بالكامل ✓ (${lessons.length} درس على جهازك)',
              style: GoogleFonts.readexPro(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      );
    }

    // 3. حالة توفر دروس للتحميل
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (PlatformHelper.isWeb) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'التحميل للاستماع دون إنترنت متاح عبر تطبيق الهاتف والحاسوب',
                  style: GoogleFonts.readexPro(),
                ),
                backgroundColor: AppColors.primaryDarkBrown,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          audioProvider.downloadSeriesBulk(series, lessons);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'بدأ تحميل الشرح كاملاً ($undownloadedCount درس) بالتتابع...',
                style: GoogleFonts.readexPro(),
              ),
              backgroundColor: AppColors.primaryDarkBrown,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.scaffoldCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dividerLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.download_for_offline_rounded,
                color: AppColors.primaryDarkBrown,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                'تحميل الشرح كاملاً ($undownloadedCount ${undownloadedCount == 1 ? "درس" : "دروس"})',
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة الدرس المرقمة (RTL: رقم الدرس يمين، التفاصيل يمين، التشغيل والإكمال يسار)
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
          color: isCompleted ? const Color(0x332E7D32) : AppColors.dividerLight,
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
                builder: (_) =>
                    LessonPlayerScreen(lesson: lesson, series: series),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // ── 1. رقم الدرس داخل دائرة على اليمين في RTL ─────────────
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

                const SizedBox(width: 12),

                // ── 2. معلومات الدرس والتفاصيل في المنتصف بمحاذاة اليمين ───
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // في RTL يبدأ من اليمين
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
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lesson.duration,
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (lesson.hasTranscript) ...[
                            const SizedBox(width: 6),
                            _buildFeatureBadge(
                              'مفرغ نصياً',
                              Icons.description_rounded,
                            ),
                          ],
                          if (lesson.hasVideo) ...[
                            const SizedBox(width: 6),
                            _buildFeatureBadge('مرئي', Icons.videocam_rounded),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── 3. زر التشغيل على اليسار في RTL ───────────────────────
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: AppColors.iconGold,
                  size: 26,
                ),

                const SizedBox(width: 4),

                // ── 4. زر تعليم الدرس كمكتمل في أقصى اليسار في RTL ────────
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
          Icon(icon, size: 10, color: AppColors.iconGold),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.readexPro(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
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
            const Icon(
              Icons.menu_book_rounded,
              size: 48,
              color: AppColors.iconGold,
            ),
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
