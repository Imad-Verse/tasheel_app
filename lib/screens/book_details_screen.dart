import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/decorated_header.dart';
import 'series_lessons_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// صفحة تفاصيل الكتاب / المتن (BookDetailsScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// مضبوطة بالكامل باتجاه اليمين إلى اليسار (RTL):
/// 1. هيدر بني مزخرف مع زر الرجوع في أقصى اليمين (RTL) بسهم موجه لليمين.
/// 2. بطاقة تعريف الكتاب الفنية (غلاف إسلامي وقور، المؤلف، القسم، الوصف).
/// 3. عنوان "الشيوخ الشارحون للكتاب" على اليمين وشارة العدد على اليسار.
/// 4. بطاقات الشيوخ الشارحين: أيقونة الشيخ على اليمين، البيانات بمحاذاة اليمين، وسهم الانتقال على اليسار.
/// ═══════════════════════════════════════════════════════════════════════════
class BookDetailsScreen extends StatelessWidget {
  final BookModel book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final category = appProvider.getCategoryById(book.categoryId);
        final seriesList = appProvider.getSeriesByBook(book.id);

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر البني العلوي المزخرف مع زر الرجوع على اليمين في RTL ──
              DecoratedHeader(
                title: book.title,
                showSearchIcon: false,
                onBackPressed: () => Navigator.pop(context),
              ),

              // ── 2. محتوى الصفحة ──────────────────────────────────────────
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    // ── بطاقة تعريف الكتاب العلوية ────────────────────────
                    _buildBookInfoCard(context, category),

                    const SizedBox(height: 24),

                    // ── قائمة الشيوخ الشارحين للكتاب (عنوان يمين، شارة يسار) ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // عنوان القسم على اليمين في RTL
                        Text(
                          'الشيوخ الشارحون للكتاب',
                          style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        // كبسولة عدد الشروحات على اليسار في RTL
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGoldBeige.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${seriesList.length} شروحات',
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (seriesList.isEmpty)
                      _buildEmptySeriesState()
                    else
                      ...seriesList.map((series) {
                        final sheikh = appProvider.getSheikhById(series.sheikhId);
                        return _buildSheikhSeriesCard(
                          context,
                          series: series,
                          sheikh: sheikh,
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

  /// بطاقة تعريف الكتاب والغلاف الفني
  Widget _buildBookInfoCard(BuildContext context, CategoryModel? category) {
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
          // غلاف الكتاب والمعلومات الأساسية
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // غلاف فني إسلامي وقور للكتاب على اليمين في RTL
              _buildArtisticBookCover(book.title),

              const SizedBox(width: 16),

              // نصوص ومعلومات الكتاب في المنتصف بمحاذاة اليمين
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // في RTL يبدأ من اليمين
                  children: [
                    if (category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentGoldBeige.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 8),

                    Text(
                      book.title,
                      style: GoogleFonts.readexPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),

                    Text(
                      'المؤلف: ${book.author}',
                      style: GoogleFonts.readexPro(
                        fontSize: 13,
                        color: AppColors.iconGold,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (book.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.dividerLight, height: 1),
            const SizedBox(height: 14),

            Text(
              'عن المتن',
              style: GoogleFonts.readexPro(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDarkBrown,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 6),

            Text(
              book.description,
              style: GoogleFonts.readexPro(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.7,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }

  /// غلاف فني إسلامي مربع
  Widget _buildArtisticBookCover(String title) {
    return Container(
      width: 90,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.primaryDarkBrown,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentGoldBeige,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BookCoverPainter(),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                title,
                style: GoogleFonts.amiri(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGoldLight,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة شرح الشيخ للكتاب (RTL: أيقونة الشيخ يمين، البيانات يمين، سهم يسار)
  Widget _buildSheikhSeriesCard(
    BuildContext context, {
    required SeriesModel series,
    required SheikhModel? sheikh,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // ── 1. أيقونة الشيخ على اليمين في RTL ──────────────────────
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldBeige.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accentGoldBeige.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.iconGold,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ── 2. معلومات الشرح في المنتصف بمحاذاة اليمين ─────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // في RTL يبدأ من اليمين
                    children: [
                      Text(
                        sheikh?.name ?? series.title,
                        style: GoogleFonts.readexPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 5),

                      // كبسولة عدد الدروس
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentGoldBeige.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${series.lessonsCount} درساً علمياً',
                          style: GoogleFonts.readexPro(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── 3. سهم الانتقال في أقصى اليسار في RTL ───────────────────
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.iconGold,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySeriesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.school_outlined, size: 44, color: AppColors.iconGold),
            const SizedBox(height: 12),
            Text(
              'لا تتوفر شروحات لهذا المتن حالياً',
              style: GoogleFonts.readexPro(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCoverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.accentGoldBeige.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // إطار داخلي للغلاف
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
        const Radius.circular(8),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
