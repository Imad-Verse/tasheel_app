import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/decorated_header.dart';
import 'series_lessons_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// صفحة تفاصيل الشيخ وسيرته وشروحاته (SheikhDetailsScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// مضبوطة بالكامل باتجاه اليمين إلى اليسار (RTL):
/// 1. هيدر بني مزخرف مع زر الرجوع في أقصى اليمين (RTL) بسهم موجه لليمين.
/// 2. لوحة زخرفية وقورة باسم الشيخ ونبذة مختصرة وزر "اقرأ السيرة كاملة".
/// 3. نافذة منبثقة أنيقة لقراءة السيرة الكاملة.
/// 4. شريط أزرار أفقي لفلترة شروحات الشيخ حسب الأقسام العلمية (الكل + الأقسام).
/// 5. عنوان "الشروحات والمتون المسجلة" على اليمين وشارة العدد على اليسار.
/// 6. بطاقات الشروحات: أيقونة الكتاب على اليمين، البيانات بمحاذاة اليمين، وسهم الانتقال على اليسار.
/// ═══════════════════════════════════════════════════════════════════════════
class SheikhDetailsScreen extends StatefulWidget {
  final SheikhModel sheikh;

  const SheikhDetailsScreen({super.key, required this.sheikh});

  @override
  State<SheikhDetailsScreen> createState() => _SheikhDetailsScreenState();
}

class _SheikhDetailsScreenState extends State<SheikhDetailsScreen> {
  String _selectedCategoryId = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final sheikhCategories = appProvider.getCategoriesForSheikh(widget.sheikh.id);
        final filteredSeries = appProvider.getSeriesBySheikh(
          widget.sheikh.id,
          categoryId: _selectedCategoryId,
        );

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر البني العلوي المزخرف مع زر الرجوع على اليمين في RTL ──
              DecoratedHeader(
                title: widget.sheikh.name,
                showSearchIcon: false,
                onBackPressed: () => Navigator.pop(context),
              ),

              // ── 2. محتوى الصفحة ──────────────────────────────────────────
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    // ── بطاقة تعريف الشيخ والسيرة ─────────────────────────
                    _buildSheikhBioCard(context),

                    const SizedBox(height: 20),

                    // ── شريط فلترة الأقسام العلمية للشيخ ─────────────────
                    _buildCategoryFilterBar(sheikhCategories),

                    const SizedBox(height: 16),

                    // ── عنوان قائمة الشروحات (عنوان يمين، شارة يسار) ───────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // عنوان القسم على اليمين في RTL
                        Text(
                          'الشروحات والمتون المسجلة',
                          style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        // كبسولة عدد الشروحات على اليسار في RTL
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentGoldBeige.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${filteredSeries.length} شروحات',
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

                    // ── قائمة الشروحات المفلترة ───────────────────────────
                    if (filteredSeries.isEmpty)
                      _buildEmptySeriesState()
                    else
                      ...filteredSeries.map((series) {
                        final book = appProvider.getBookById(series.bookId);
                        final cat = appProvider.getCategoryById(series.categoryId);
                        return _buildSeriesCard(
                          context,
                          series: series,
                          book: book,
                          category: cat,
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

  /// بطاقة تعريف الشيخ والسيرة المختصرة
  Widget _buildSheikhBioCard(BuildContext context) {
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
          // لوحة زخرفية إسلامية باسم الشيخ
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryDarkBrown,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accentGoldBeige,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.textGoldLight,
                  size: 26,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.sheikh.name,
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGoldLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // النبذة المختصرة
          Text(
            widget.sheikh.shortBio,
            style: GoogleFonts.readexPro(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
            textAlign: TextAlign.right,
          ),

          const SizedBox(height: 16),

          // زر "اقرأ السيرة كاملة"
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openFullBioModal(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'اقرأ السيرة كاملة',
                      style: GoogleFonts.readexPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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

  /// النافذة المنبثقة للسيرة الكاملة (Modal Bottom Sheet)
  void _openFullBioModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.scaffoldCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // مقبض السحب
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // شريط العنوان
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    Text(
                      'ترجمة ${widget.sheikh.name}',
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.dividerLight),

              // نص السيرة الكاملة
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.dividerLight),
                    ),
                    child: Text(
                      widget.sheikh.fullBio.isNotEmpty
                          ? widget.sheikh.fullBio
                          : widget.sheikh.shortBio,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        height: 2.1,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
              ),

              // زر إغلاق في الأسفل
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkBrown,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'إغلاق',
                      style: GoogleFonts.readexPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// شريط أزرار الفلترة الأفقية للأقسام
  Widget _buildCategoryFilterBar(List<CategoryModel> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // خيار "الكل"
          _buildFilterChip(
            label: 'الكل',
            isSelected: _selectedCategoryId == 'all',
            onTap: () {
              setState(() => _selectedCategoryId = 'all');
            },
          ),
          const SizedBox(width: 8),

          // خيارات الأقسام العلمية الخاصة بالشيخ
          ...categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildFilterChip(
                label: cat.name,
                isSelected: _selectedCategoryId == cat.id,
                onTap: () {
                  setState(() => _selectedCategoryId = cat.id);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDarkBrown : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryDarkBrown : AppColors.dividerLight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDarkBrown.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.readexPro(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// بطاقة الشرح (RTL: أيقونة الكتاب يمين، البيانات يمين، سهم يسار)
  Widget _buildSeriesCard(
    BuildContext context, {
    required SeriesModel series,
    required BookModel? book,
    required CategoryModel? category,
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
                  sheikh: widget.sheikh,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                // ── 1. أيقونة الكتاب على اليمين في RTL ────────────────────
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldBeige.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentGoldBeige.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.iconGold,
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ── 2. معلومات الكتاب والشرح في المنتصف بمحاذاة اليمين ─────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // في RTL يبدأ من اليمين
                    children: [
                      Text(
                        book?.title ?? series.title,
                        style: GoogleFonts.readexPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGoldBeige.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${series.lessonsCount} درس',
                              style: GoogleFonts.readexPro(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (category != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              category.name,
                              style: GoogleFonts.readexPro(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
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
              'لا تتوفر شروحات للشيخ في هذا القسم',
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
