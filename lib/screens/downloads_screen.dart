import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/audio_provider.dart';
import '../services/mock_data_service.dart';
import 'lesson_player_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة التنزيلات للاستماع بدون إنترنت (DownloadsScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تعرض الدروس المحملة محلياً مجمعة حسب الشرح (الكتاب + الشيخ)،
/// مع إمكانية تشغيلها بدون اتصال بالشبكة أو حذفها لتفريغ المساحة.
/// ═══════════════════════════════════════════════════════════════════════════
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  // تتبع الشروحات المفتوحة لعرض دروسها المحملة
  final Set<String> _expandedSeriesIds = {};

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final downloadedSeries = audioProvider.downloadedSeries;
    final totalDownloadedLessons = audioProvider.downloadedLessons.length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      body: Column(
        children: [
          // ── 1. الهيدر العلوي ─────────────────────────────────────────────
          _buildDownloadsHeader(context, audioProvider, totalDownloadedLessons),

          // ── 2. المحتوى ──────────────────────────────────────────────────
          Expanded(
            child: downloadedSeries.isEmpty
                ? _buildEmptyDownloadsState(context, appProvider)
                : _buildDownloadedSeriesList(context, audioProvider, downloadedSeries),
          ),
        ],
      ),
    );
  }

  /// الهيدر العلوي المزخرف مع زر الرجوع وإفراغ التنزيلات
  Widget _buildDownloadsHeader(
    BuildContext context,
    AudioProvider audioProvider,
    int totalCount,
  ) {
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
      child: Column(
        children: [
          Row(
            children: [
              // زر إفراغ التنزيلات على اليسار في RTL (إن وجدت دروس)
              if (totalCount > 0)
                IconButton(
                  tooltip: 'إفراغ كافة التنزيلات',
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: AppColors.textGoldLight,
                    size: 24,
                  ),
                  onPressed: () => _confirmClearAllDownloads(context, audioProvider),
                )
              else
                const SizedBox(width: 44),

              // العنوان في المنتصف
              Expanded(
                child: Text(
                  'التنزيلات (بدون إنترنت)',
                  style: GoogleFonts.readexPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // زر الرجوع على اليمين في RTL
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
          if (totalCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.patternBrown.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textGoldLight.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '$totalCount دروس محملة متاحة بدون اتصال بالشبكة',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: AppColors.textGoldLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// الحالة الفارغة عند عدم وجود أي تنزيلات
  Widget _buildEmptyDownloadsState(BuildContext context, AppProvider appProvider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.accentGoldBeige.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.cloud_download_outlined,
                color: AppColors.iconGold,
                size: 46,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'لا توجد دروس محملة',
              style: GoogleFonts.readexPro(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDarkBrown,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد دروس محملة للاستماع بدون إنترنت حالياً. يمكنك تحميل أي درس من صفحة مشغل الصوت أو قائمة دروس الشرح.',
              style: GoogleFonts.readexPro(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                appProvider.setCurrentTab(1);
              },
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: Text(
                'تصفح المتون لتحميل الدروس',
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkBrown,
                foregroundColor: AppColors.textGoldLight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// قائمة الشروحات التي تحتوي على دروس محملة
  Widget _buildDownloadedSeriesList(
    BuildContext context,
    AudioProvider audioProvider,
    List<SeriesModel> seriesList,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: seriesList.length,
      itemBuilder: (context, index) {
        final series = seriesList[index];
        final book = MockDataService.getBookById(series.bookId);
        final sheikh = MockDataService.getSheikhById(series.sheikhId);
        final category = MockDataService.getCategoryById(series.categoryId);
        final lessons = audioProvider.getDownloadedLessonsForSeries(series.id);
        final isExpanded = _expandedSeriesIds.contains(series.id);

        final countText = lessons.length == 1
            ? 'درس واحد محمل'
            : lessons.length == 2
                ? 'درسان محملان'
                : '${lessons.length} دروس محملة';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
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
            children: [
              // ── بطاقة رأس الشرح ──────────────────────────────────────
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedSeriesIds.remove(series.id);
                      } else {
                        _expandedSeriesIds.add(series.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // سهم التوسيع/الطي
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.iconGold,
                          size: 26,
                        ),

                        const Spacer(),

                        // المعلومات
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // كبسولة عدد الدروس المحملة
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGoldBeige
                                          .withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      countText,
                                      style: GoogleFonts.readexPro(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDarkBrown,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // كبسولة القسم
                                  if (category != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.scaffoldCream,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppColors.dividerLight),
                                      ),
                                      child: Text(
                                        category.name,
                                        style: GoogleFonts.readexPro(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.iconGold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // عنوان الشرح المجمع (الكتاب + الشيخ)
                              Text(
                                '${book?.title ?? series.title} - شرح ${sheikh?.name ?? "الشيخ"}',
                                style: GoogleFonts.readexPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDarkBrown,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // أيقونة المجلد / التنزيل
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.accentGoldBeige
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.folder_special_rounded,
                            color: AppColors.iconGold,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── قائمة الدروس المحملة المنسدلة ─────────────────────────
              if (isExpanded) ...[
                const Divider(height: 1, color: AppColors.dividerLight),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: lessons.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.dividerLight),
                  itemBuilder: (ctx, lIdx) {
                    final lesson = lessons[lIdx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          // زر حذف التنزيل
                          IconButton(
                            tooltip: 'حذف من الجهاز',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFC62828),
                              size: 20,
                            ),
                            onPressed: () => _confirmDeleteLesson(
                              context,
                              audioProvider,
                              lesson,
                            ),
                          ),

                          // زر تشغيل الدرس بدون إنترنت
                          ElevatedButton.icon(
                            onPressed: () {
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
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text(
                              'استماع',
                              style: GoogleFonts.readexPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDarkBrown,
                              foregroundColor: AppColors.textGoldLight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // عنوان الدرس ومدته
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                lesson.title,
                                style: GoogleFonts.readexPro(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${lesson.duration} د • محمل على الجهاز',
                                    style: GoogleFonts.readexPro(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.offline_pin_rounded,
                                    color: Color(0xFF2E7D32),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// تأكيد حذف درس معين
  void _confirmDeleteLesson(
    BuildContext context,
    AudioProvider audioProvider,
    LessonModel lesson,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف الدرس المحمل',
          style: GoogleFonts.readexPro(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDarkBrown,
          ),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'هل تريد بالتأكيد حذف ملف (${lesson.title}) من جهازك لتوفير المساحة؟',
          style: GoogleFonts.readexPro(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.readexPro(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              audioProvider.deleteDownload(lesson.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم حذف الملف من التنزيلات بنجاح',
                    style: GoogleFonts.readexPro(),
                  ),
                  backgroundColor: AppColors.primaryDarkBrown,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: AppColors.textWhite,
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.readexPro(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// تأكيد إفراغ كافة التنزيلات
  void _confirmClearAllDownloads(
    BuildContext context,
    AudioProvider audioProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'إفراغ كافة التنزيلات',
          style: GoogleFonts.readexPro(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDarkBrown,
          ),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'هل تريد بالتأكيد حذف جميع الدروس المحملة على جهازك؟ لن تتمكن من الاستماع إليها بدون اتصال بالشبكة.',
          style: GoogleFonts.readexPro(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.readexPro(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              audioProvider.clearAllDownloads();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم إفراغ كافة التنزيلات بنجاح',
                    style: GoogleFonts.readexPro(),
                  ),
                  backgroundColor: AppColors.primaryDarkBrown,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: AppColors.textWhite,
            ),
            child: Text(
              'إفراغ الكل',
              style: GoogleFonts.readexPro(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
