import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/audio_provider.dart';
import '../services/mock_data_service.dart';
import 'downloads_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة مدير التخزين الذكي (StorageManagerScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تعرض إحصائيات المساحة الفعلية المستهلكة للتطبيق على الجهاز مع إمكانية:
/// - إفراغ كافة التنزيلات بضغطة واحدة.
/// - إفراغ مساحة شروحات معينة واسترجاع مساحتها فوراً.
/// ═══════════════════════════════════════════════════════════════════════════
class StorageManagerScreen extends StatelessWidget {
  const StorageManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AudioProvider, AppProvider>(
      builder: (context, audioProvider, appProvider, child) {
        final totalBytes = audioProvider.getTotalStorageBytes();
        final formattedTotal = AudioProvider.formatBytes(totalBytes);
        final downloadedSeries = audioProvider.downloadedSeries;
        final totalLessonsCount = audioProvider.downloadedLessons.length;

        // تقدير النسبة من مساحة تخزينية مرجعية (مثلاً 2 جيجابايت كحد أقصى مريح للطالب)
        const int referenceMaxBytes = 2 * 1024 * 1024 * 1024;
        final double storageRatio = (totalBytes / referenceMaxBytes).clamp(0.02, 1.0);

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر العلوي المزخرف ─────────────────────────────────
              _buildHeader(context, audioProvider, totalLessonsCount),

              // ── 2. المحتوى الرئيسي ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── بطاقة إجمالي المساحة والمؤشر البصري ───────────────
                      _buildTotalStorageCard(
                        context: context,
                        audioProvider: audioProvider,
                        formattedTotal: formattedTotal,
                        totalBytes: totalBytes,
                        totalLessonsCount: totalLessonsCount,
                        storageRatio: storageRatio,
                      ),

                      const SizedBox(height: 20),

                      // ── عنوان قسم الشروحات المحملة ────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.folder_special_rounded,
                                size: 20,
                                color: AppColors.primaryDarkBrown,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'الشروحات المحملة حسب المساحة',
                                style: GoogleFonts.readexPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDarkBrown,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGoldBeige.withValues(
                                alpha: 0.25,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${downloadedSeries.length} شروحات',
                              style: GoogleFonts.readexPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDarkBrown,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── قائمة الشروحات مع أحجامها وأزرار تفريغ مساحتها ───
                      if (downloadedSeries.isEmpty)
                        _buildEmptyStorageCard(context)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: downloadedSeries.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final series = downloadedSeries[index];
                            final seriesLessons = audioProvider
                                .getDownloadedLessonsForSeries(series.id);
                            final seriesBytes = audioProvider
                                .getSeriesStorageBytes(series.id, seriesLessons);
                            final book = appProvider.getBookById(series.bookId) ??
                                MockDataService.getBookById(series.bookId);
                            final sheikh = appProvider.getSheikhById(series.sheikhId) ??
                                MockDataService.getSheikhById(series.sheikhId);

                            return _buildSeriesStorageCard(
                              context: context,
                              series: series,
                              seriesLessons: seriesLessons,
                              seriesBytes: seriesBytes,
                              book: book,
                              sheikh: sheikh,
                              audioProvider: audioProvider,
                            );
                          },
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

  /// الهيدر العلوي البني المزخرف
  Widget _buildHeader(
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
      child: Row(
        children: [
          // زر الرجوع في RTL
          IconButton(
            tooltip: 'رجوع',
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textGoldLight,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),

          // العنوان في المنتصف
          Expanded(
            child: Text(
              'إدارة المساحة التخزينية',
              style: GoogleFonts.readexPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // زر الانتقال للتنزيلات
          IconButton(
            tooltip: 'شاشة التنزيلات',
            icon: const Icon(
              Icons.cloud_done_rounded,
              color: AppColors.textGoldLight,
              size: 22,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// بطاقة إجمالي المساحة التخزينية المستهلكة
  Widget _buildTotalStorageCard({
    required BuildContext context,
    required AudioProvider audioProvider,
    required String formattedTotal,
    required int totalBytes,
    required int totalLessonsCount,
    required double storageRatio,
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
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkBrown.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentGoldBeige.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: AppColors.primaryDarkBrown,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المساحة المستهلكة',
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedTotal,
                      style: GoogleFonts.readexPro(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '$totalLessonsCount',
                      style: GoogleFonts.readexPro(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                    Text(
                      'درس محمل',
                      style: GoogleFonts.readexPro(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // شريط المؤشر البصري الأنيق
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalBytes > 0 ? storageRatio : 0.0,
              backgroundColor: AppColors.dividerLight.withValues(alpha: 0.6),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryDarkBrown,
              ),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الدروس الصوتية المحملة',
                style: GoogleFonts.readexPro(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                totalBytes > 0 ? 'متاحة بدون اتصال بالإنترنت' : 'لا توجد ملفات مخزنة',
                style: GoogleFonts.readexPro(
                  fontSize: 11,
                  color: AppColors.iconGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (totalBytes > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.dividerLight, height: 1),
            const SizedBox(height: 12),

            // زر إفراغ الكل
            OutlinedButton.icon(
              onPressed: () => _confirmClearAll(context, audioProvider),
              icon: const Icon(
                Icons.delete_sweep_rounded,
                size: 20,
                color: Colors.red,
              ),
              label: Text(
                'إفراغ كافة التنزيلات وتفريغ المساحة',
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// بطاقة شرح محمل مع حجمه الفعلي وزر إفراغ مساحته
  Widget _buildSeriesStorageCard({
    required BuildContext context,
    required SeriesModel series,
    required List<LessonModel> seriesLessons,
    required int seriesBytes,
    required BookModel? book,
    required SheikhModel? sheikh,
    required AudioProvider audioProvider,
  }) {
    final formattedSeriesSize = AudioProvider.formatBytes(seriesBytes);

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة الكتاب / الشرح
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primaryDarkBrown,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // تفاصيل الشرح
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title.isNotEmpty
                          ? series.title
                          : (book?.title ?? 'شرح علمي'),
                      style: GoogleFonts.readexPro(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sheikh?.name ?? 'فضيلة الشيخ',
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // شارة الحجم التخزيني للشرح
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkBrown.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentGoldBeige.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  formattedSeriesSize,
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarkBrown,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.dividerLight, height: 1),
          const SizedBox(height: 10),

          // السطر السفلي: عدد الدروس وزر إفراغ الشرح
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.audiotrack_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${seriesLessons.length} دروس محملة',
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // زر إفراغ مساحة هذا الشرح فقط
              InkWell(
                onTap: () => _confirmClearSeries(
                  context,
                  audioProvider,
                  series,
                  seriesLessons,
                  formattedSeriesSize,
                ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'إفراغ المساحة',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// الحالة الفارغة عند عدم وجود تنزيلات
  Widget _buildEmptyStorageCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.iconGold,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مساحة مستهلكة',
            style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkBrown,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'لم تقم بتحميل أي دروس صوتية بعد. يمكنك تحميل الدروس من صفحة المشغل للاستماع بدون إنترنت في أي وقت.',
            style: GoogleFonts.readexPro(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// نافذة تأكيد إفراغ كافة التنزيلات
  void _confirmClearAll(BuildContext context, AudioProvider audioProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              'إفراغ كافة التنزيلات؟',
              style: GoogleFonts.readexPro(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkBrown,
              ),
            ),
          ],
        ),
        content: Text(
          'سيتم حذف جميع الملفات الصوتية المحملة على الهاتف واسترجاع كامل المساحة التخزينية. لن يؤثر ذلك على تقدمك في الورد أو محفوظاتك.',
          style: GoogleFonts.readexPro(
            fontSize: 13,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.readexPro(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await audioProvider.clearAllDownloads();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم إفراغ كافة التنزيلات وتفريغ المساحة بنجاح',
                      style: GoogleFonts.readexPro(),
                    ),
                    backgroundColor: AppColors.primaryDarkBrown,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إفراغ الكل',
              style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// نافذة تأكيد إفراغ شرح معين
  void _confirmClearSeries(
    BuildContext context,
    AudioProvider audioProvider,
    SeriesModel series,
    List<LessonModel> seriesLessons,
    String formattedSize,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              'إفراغ مساحة هذا الشرح؟',
              style: GoogleFonts.readexPro(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkBrown,
              ),
            ),
          ],
        ),
        content: Text(
          'سيتم حذف ${seriesLessons.length} دروس محملة لهذا الشرح واسترجاع مساحة تقدر بـ $formattedSize.',
          style: GoogleFonts.readexPro(
            fontSize: 13,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.readexPro(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await audioProvider.deleteSeriesDownloads(series.id, seriesLessons);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم إفراغ مساحة الشرح بنجاح واسترجاع $formattedSize',
                      style: GoogleFonts.readexPro(),
                    ),
                    backgroundColor: AppColors.primaryDarkBrown,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إفراغ المساحة',
              style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
