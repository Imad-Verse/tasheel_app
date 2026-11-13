import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/decorated_header.dart';
import '../widgets/global_search_delegate.dart';
import 'category_books_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة المتون / الأقسام العلمية (CategoriesScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تتضمن:
/// 1. هيدر بني مزخرف مع عنوان "المتون" وزر البحث.
/// 2. شريط تحكم يضم عنوان "جميع المتون العلمية" وزر التبديل (قائمة / شبكة 3 في السطر).
/// 3. وضع القائمة (List View) مطابق للصورة المرجعية الثالثة.
/// 4. وضع الشبكة (Grid View - 3 في السطر) بزخرفة إسلامية وقورة ونسبة 1:1.
/// 5. انتقال عند النقر لعرض كتب ومتون القسم.
/// ═══════════════════════════════════════════════════════════════════════════
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final categories = appProvider.categories;
        final isGrid = appProvider.isCategoriesGridView;

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر البني العلوي المزخرف ─────────────────────────
              DecoratedHeader(
                title: 'المتون',
                showSearchIcon: true,
                onSearchPressed: () => GlobalSearchDelegate.show(context),
              ),

              // ── 2. شريط العنوان وزر التبديل بين القائمة والشبكة ─────────
              _buildControlBar(context, appProvider, isGrid),

              // ── 3. عرض الأقسام (قائمة أو شبكة) ──────────────────────────
              Expanded(
                child: isGrid
                    ? _buildGridView(context, categories)
                    : _buildListView(context, categories),
              ),
            ],
          ),
        );
      },
    );
  }

  /// شريط التحكم: العنوان وزر التبديل
  Widget _buildControlBar(
    BuildContext context,
    AppProvider appProvider,
    bool isGrid,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر التبديل بين العرضين على اليسار في RTL
          InkWell(
            onTap: () => appProvider.toggleCategoriesView(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.dividerLight),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGrid
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    color: AppColors.iconGold,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isGrid ? 'قائمة' : 'شبكة',
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // عنوان القسم على اليمين في RTL
          Text(
            'جميع المتون العلمية',
            style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// ── 3.1 وضع القائمة (مطابق للصورة المرجعية الثالثة) ────────────────────
  Widget _buildListView(
    BuildContext context,
    List<CategoryModel> categories,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _buildCategoryListCard(context, cat);
      },
    );
  }

  Widget _buildCategoryListCard(BuildContext context, CategoryModel cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCategoryBooks(context, cat),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // سهم التنقل في أقصى اليسار
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.iconGold,
                  size: 22,
                ),

                const Spacer(),

                // معلومات القسم (الاسم + البيانات التفصيلية)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      cat.name,
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cat.booksCount} متون  •  ${cat.sheikhsCount} شيوخ  •  ${cat.lessonsCount} درس',
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // أيقونة النجمة والزخرفة الإسلامية الذهبية
                _buildIslamicStarBadge(cat.iconName),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// أيقونة النجمة الإسلامية الزخرفية
  Widget _buildIslamicStarBadge(String iconName) {
    return Container(
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
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppColors.iconGold,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// ── 3.2 وضع المربعات (Grid View - 3 في كل سطر) ─────────────────────────
  Widget _buildGridView(
    BuildContext context,
    List<CategoryModel> categories,
  ) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 مربعات في كل سطر كما طُلب
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72, // نسبة تسمح بالمربع 1:1 مع النص تحته بدون overflow
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _buildCategoryGridTile(context, cat);
      },
    );
  }

  Widget _buildCategoryGridTile(BuildContext context, CategoryModel cat) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // المربع 1:1 بتصميم زخرفي إسلامي وقور
        AspectRatio(
          aspectRatio: 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openCategoryBooks(context, cat),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentGoldBeige.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // زخرفة إسلامية خفيفة في زوايا المربع
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SquareOrnamentPainter(),
                      ),
                    ),
                    // أيقونة القسم في الوسط
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(cat.iconName),
                          color: AppColors.primaryDarkBrown,
                          size: 24,
                        ),
                      ),
                    ),
                    // شارة عدد الكتب في الزاوية العلوية
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkBrown,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cat.booksCount}',
                          style: GoogleFonts.readexPro(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGoldLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // اسم القسم تحت المربع
        Text(
          cat.name,
          style: GoogleFonts.readexPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.auto_awesome_rounded;
      case 'balance':
        return Icons.balance_rounded;
      case 'foundation':
        return Icons.account_balance_rounded;
      case 'scroll':
        return Icons.history_edu_rounded;
      case 'pie_chart':
        return Icons.pie_chart_outline_rounded;
      case 'language':
        return Icons.translate_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  /// فتح صفحة كتب ومتون القسم العلمي
  void _openCategoryBooks(BuildContext context, CategoryModel cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryBooksScreen(category: cat),
      ),
    );
  }
}

/// رسام الزخرفة الإسلامية للمربعات في وضع الشبكة
class _SquareOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentGoldBeige.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const cornerSize = 14.0;

    // زوايا زخرفية في الأركان الأربعة
    // أعلى يسار
    canvas.drawLine(const Offset(4, 4 + cornerSize), const Offset(4, 4), paint);
    canvas.drawLine(const Offset(4, 4), const Offset(4 + cornerSize, 4), paint);

    // أعلى يمين
    canvas.drawLine(Offset(size.width - 4, 4 + cornerSize), Offset(size.width - 4, 4), paint);
    canvas.drawLine(Offset(size.width - 4, 4), Offset(size.width - 4 - cornerSize, 4), paint);

    // أسفل يسار
    canvas.drawLine(Offset(4, size.height - 4 - cornerSize), Offset(4, size.height - 4), paint);
    canvas.drawLine(Offset(4, size.height - 4), Offset(4 + cornerSize, size.height - 4), paint);

    // أسفل يمين
    canvas.drawLine(Offset(size.width - 4, size.height - 4 - cornerSize), Offset(size.width - 4, size.height - 4), paint);
    canvas.drawLine(Offset(size.width - 4, size.height - 4), Offset(size.width - 4 - cornerSize, size.height - 4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
