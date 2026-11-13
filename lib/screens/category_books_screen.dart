import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/decorated_header.dart';
import 'book_details_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة كتب ومتون القسم العلمي (CategoryBooksScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// مضبوطة بالكامل باتجاه اليمين إلى اليسار (RTL):
/// - هيدر بني مزخرف مع زر الرجوع في أقصى اليمين (RTL) بسهم موجه لليمين.
/// - شريط تحكم: عدد المتون على اليمين، وزر تبديل العرض (قائمة/شبكة) على اليسار.
/// - وضع القائمة: غلاف الكتاب على اليمين، البيانات بمحاذاة اليمين، وسهم الانتقال على اليسار.
/// - وضع الشبكة (3 في السطر بنسبة 1:1 وغلاف إسلامي وقور).
/// - عند الضغط ينتقل المستخدم لصفحة تفاصيل الكتاب (BookDetailsScreen).
/// ═══════════════════════════════════════════════════════════════════════════
class CategoryBooksScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryBooksScreen({super.key, required this.category});

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final books = appProvider.getBooksByCategory(widget.category.id);

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      body: Column(
        children: [
          // ── 1. الهيدر البني العلوي المزخرف مع زر الرجوع على اليمين في RTL ──
          DecoratedHeader(
            title: 'متون ${widget.category.name}',
            showSearchIcon: false,
            onBackPressed: () => Navigator.pop(context),
          ),

          // ── 2. شريط التحكم وزر تبديل العرض ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── عدد الكتب المتوفرة على اليمين في RTL ───────────────────
                Text(
                  '${books.length} متون معتمدة',
                  style: GoogleFonts.readexPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                // ── زر التبديل بين القائمة والشبكة على اليسار في RTL ───────
                InkWell(
                  onTap: () {
                    setState(() => _isGridView = !_isGridView);
                  },
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
                          _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          color: AppColors.iconGold,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isGridView ? 'قائمة' : 'شبكة',
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
              ],
            ),
          ),

          // ── 3. عرض الكتب (قائمة أو شبكة) ────────────────────────────────
          Expanded(
            child: books.isEmpty
                ? _buildEmptyState()
                : _isGridView
                    ? _buildGridView(context, books)
                    : _buildListView(context, books),
          ),
        ],
      ),
    );
  }

  /// وضع القائمة (مرتب من اليمين لليسار)
  Widget _buildListView(BuildContext context, List<BookModel> books) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dividerLight),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookDetailsScreen(book: book),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // ── 1. غلاف مصغر للكتاب على اليمين في RTL ─────────────
                    _buildMiniCover(book.title),

                    const SizedBox(width: 14),

                    // ── 2. نصوص ومعلومات الكتاب في المنتصف بمحاذاة اليمين ───
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // في RTL يبدأ من اليمين
                        children: [
                          Text(
                            book.title,
                            style: GoogleFonts.readexPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'المؤلف: ${book.author}',
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGoldBeige.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${book.seriesCount} شروحات متوفرة',
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

                    // ── 3. سهم الانتقال في أقصى اليسار في RTL ──────────────
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
      },
    );
  }

  /// وضع الشبكة (3 في السطر)
  Widget _buildGridView(BuildContext context, List<BookModel> books) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailsScreen(book: book),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkBrown,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accentGoldBeige,
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
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          book.title,
                          style: GoogleFonts.amiri(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textGoldLight,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              book.title,
              style: GoogleFonts.readexPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniCover(String title) {
    return Container(
      width: 52,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primaryDarkBrown,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.accentGoldBeige,
          width: 1,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: GoogleFonts.amiri(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textGoldLight,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.iconGold),
            const SizedBox(height: 12),
            Text(
              'لا توجد متون مضافة لهذا القسم حالياً',
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
