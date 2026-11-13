import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mock_data_service.dart';
import '../widgets/decorated_header.dart';
import '../widgets/global_search_delegate.dart';
import 'series_lessons_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة المحفوظات والمتون قيد الدراسة (BookmarksScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تعرض فقط الشروحات المضافة صراحةً في `studiedSeriesIds`.
/// ═══════════════════════════════════════════════════════════════════════════
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final studiedSeries = appProvider.getStudiedSeries();

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر العلوي المزخرف ─────────────────────────────────
              DecoratedHeader(
                title: 'المتون المحفوظة',
                showSearchIcon: true,
                onSearchPressed: () => GlobalSearchDelegate.show(context),
              ),

              // ── 2. شريط عدد المتون ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentGoldBeige.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentGoldBeige.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${studiedSeries.length} متون',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDarkBrown,
                        ),
                      ),
                    ),
                    Text(
                      'المتون قيد الدراسة',
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── 3. قائمة المحفوظات أو الحالة الفارغة ────────────────────
              Expanded(
                child: studiedSeries.isEmpty
                    ? _buildEmptyState(context, appProvider)
                    : _buildStudiedList(context, studiedSeries, appProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  /// الحالة الفارغة عند عدم وجود أي متن في المحفوظات
  Widget _buildEmptyState(BuildContext context, AppProvider appProvider) {
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
                Icons.bookmark_outline_rounded,
                color: AppColors.iconGold,
                size: 46,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'لا توجد متون محفوظة',
              style: GoogleFonts.readexPro(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDarkBrown,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لم تقم بإضافة أي متن للمحفوظات بعد. ادخل إلى أي كتاب واضغط على (بدء دراسة هذا المتن) ليظهر هنا',
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
                // الانتقال لتبويب المتون العلمية (الفهرس 1)
                appProvider.setCurrentTab(1);
              },
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: Text(
                'تصفح المتون العلمية',
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

  /// قائمة المتون قيد الدراسة
  Widget _buildStudiedList(
    BuildContext context,
    List<SeriesModel> list,
    AppProvider appProvider,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final series = list[index];
        final book = MockDataService.getBookById(series.bookId);
        final sheikh = MockDataService.getSheikhById(series.sheikhId);
        final category = MockDataService.getCategoryById(series.categoryId);

        final totalLessons = series.lessonsCount;
        final completedLessons = appProvider.getCompletedLessonsInSeries(series.id);
        final progress = (totalLessons > 0)
            ? (completedLessons / totalLessons).clamp(0.0, 1.0)
            : 0.0;
        final percent = (progress * 100).toInt();

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── الصف العلوي: القسم واسم الكتاب والشيخ ─────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // أيقونة الحذف من المحفوظات على اليسار في RTL
                    IconButton(
                      tooltip: 'إزالة من المحفوظات',
                      icon: const Icon(
                        Icons.bookmark_remove_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      onPressed: () {
                        appProvider.toggleStudySeries(series.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تمت إزالة (${book?.title ?? series.title}) من المحفوظات',
                              style: GoogleFonts.readexPro(),
                            ),
                            backgroundColor: AppColors.primaryDarkBrown,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    const Spacer(),

                    // معلومات الكتاب والشيخ والكبسولة
                    Expanded(
                      flex: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // كبسولة القسم
                          if (category != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.scaffoldCream,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.dividerLight),
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

                          // اسم الكتاب
                          Text(
                            book?.title ?? series.title,
                            style: GoogleFonts.readexPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDarkBrown,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 4),

                          // اسم الشيخ الشارح
                          Text(
                            'الشارح: ${sheikh?.name ?? "الشيخ"}',
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

                    // أيقونة المتن البنية
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkBrown,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.textGoldLight,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── شريط التقدم ──────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$percent%',
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iconGold,
                          ),
                        ),
                        Text(
                          'أتممت $completedLessons من $totalLessons درساً - $percent%',
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: AppColors.dividerLight.withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentGoldBeige,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── زر متابعة الدراسة ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SeriesLessonsScreen(
                            series: series,
                            book: book,
                            sheikh: sheikh,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      'متابعة الدراسة',
                      style: GoogleFonts.readexPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.scaffoldCream,
                      foregroundColor: AppColors.primaryDarkBrown,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.accentGoldBeige, width: 1.2),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
