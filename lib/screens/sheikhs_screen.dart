import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/decorated_header.dart';
import '../widgets/global_search_delegate.dart';
import 'sheikh_details_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة الشيوخ والعلماء (SheikhsScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// مضبوطة بالكامل باتجاه اليمين إلى اليسار (RTL):
/// 1. هيدر بني مزخرف مع عنوان "الشيوخ" وزر البحث.
/// 2. شريط تحكم يضم: عنوان "جميع الشيوخ والعلماء" على اليمين، وزر التبديل (قائمة/شبكة) على اليسار.
/// 3. وضع القائمة (List View): أيقونة الشيخ/الكتاب على اليمين، البيانات بمحاذاة اليمين، وسهم الانتقال على اليسار.
/// 4. وضع الشبكة (Grid View - 3 في السطر): بطاقة 1:1 بإطار وزخرفة إسلامية
///    واسم الشيخ بخط أميري وقور دون أي صور بشرية، وتحتها الاسم.
/// 5. تفاصيل سيرة الشيخ وقائمة شروحاته عند النقر.
/// ═══════════════════════════════════════════════════════════════════════════
class SheikhsScreen extends StatelessWidget {
  const SheikhsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final sheikhs = appProvider.sheikhs;
        final isGrid = appProvider.isSheikhsGridView;

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر البني العلوي المزخرف ─────────────────────────
              DecoratedHeader(
                title: 'الشيوخ',
                showSearchIcon: true,
                onSearchPressed: () => GlobalSearchDelegate.show(context),
              ),

              // ── 2. شريط التحكم وزر التبديل بين القائمة والشبكة ─────────
              _buildControlBar(context, appProvider, isGrid),

              // ── 3. عرض الشيوخ (قائمة أو شبكة) ───────────────────────────
              Expanded(
                child: isGrid
                    ? _buildGridView(context, sheikhs)
                    : _buildListView(context, sheikhs),
              ),
            ],
          ),
        );
      },
    );
  }

  /// شريط التحكم: العنوان على اليمين وزر التبديل على اليسار في RTL
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
          // ── عنوان القسم على اليمين في RTL ──────────────────────────
          Text(
            'جميع الشيوخ والعلماء',
            style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          // ── زر التبديل بين العرضين على اليسار في RTL ───────────────
          InkWell(
            onTap: () => appProvider.toggleSheikhsView(),
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
        ],
      ),
    );
  }

  /// ── 3.1 وضع القائمة (List View) ───────────────────────────────────────
  Widget _buildListView(BuildContext context, List<SheikhModel> sheikhs) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: sheikhs.length,
      itemBuilder: (context, index) {
        final sheikh = sheikhs[index];
        return _buildSheikhListCard(context, sheikh);
      },
    );
  }

  Widget _buildSheikhListCard(BuildContext context, SheikhModel sheikh) {
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
          onTap: () => _openSheikhDetails(context, sheikh),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // ── 1. أيقونة الشيخ (شخص) بخلفية داكنة ولون فاتح على اليمين في RTL ──
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2723), // بني قاتم داكن
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accentGoldBeige.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded, // مطابقة لأيقونة الشيوخ في الشريط السفلي
                      color: Color(0xFFFFF8E7), // كريمي فاتح وقور
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ── 2. معلومات الشيخ في المنتصف بمحاذاة اليمين ─────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // في RTL يبدأ من اليمين
                    children: [
                      Text(
                        sheikh.name,
                        style: GoogleFonts.readexPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sheikh.booksCount} شروحات  •  ${sheikh.lessonsCount} درس',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── 3. سهم التنقل في أقصى اليسار في RTL ───────────────────
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.iconGold,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ── 3.2 وضع المربعات (Grid View - 3 في كل سطر) ─────────────────────────
  Widget _buildGridView(BuildContext context, List<SheikhModel> sheikhs) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 مربعات في كل سطر
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72, // المربع 1:1 مع اسم الشيخ تحته دون overflow
      ),
      itemCount: sheikhs.length,
      itemBuilder: (context, index) {
        final sheikh = sheikhs[index];
        return _buildSheikhGridTile(context, sheikh);
      },
    );
  }

  Widget _buildSheikhGridTile(BuildContext context, SheikhModel sheikh) {
    // استخراج اللقب المختصر للشيخ لعرضه في الإطار الزخرفي (مثل: "ابن عثيمين")
    final shortName = _getShortSheikhName(sheikh.name);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // المربع 1:1 بغلاف زخرفي إسلامي وقور
        AspectRatio(
          aspectRatio: 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openSheikhDetails(context, sheikh),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkBrown,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentGoldBeige,
                    width: 1.5,
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
                    // الزخرفة الهندسية في الخلفية
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SheikhCardOrnamentPainter(),
                      ),
                    ),

                    // إطار بيضاوي إسلامي في المنتصف بداخله اسم الشيخ بخط أميري
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.accentGoldBeige.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.patternBrown.withValues(alpha: 0.6),
                        ),
                        child: Text(
                          shortName,
                          style: GoogleFonts.amiri(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textGoldLight,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // شارة عدد الشروحات في الأسفل
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accentGoldBeige,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${sheikh.booksCount} شروحات',
                            style: GoogleFonts.readexPro(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
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

        // اسم الشيخ أسفل المربع
        Text(
          sheikh.name,
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
  }

  /// تبسيط اسم الشيخ للعرض المصغر في الإطار
  String _getShortSheikhName(String fullName) {
    if (fullName.contains('ابن عثيمين') || fullName.contains('العثيمين')) {
      return 'الشيخ\nابن عثيمين';
    }
    if (fullName.contains('ابن باز') || fullName.contains('بن باز')) {
      return 'الشيخ\nابن باز';
    }
    if (fullName.contains('الفوزان')) {
      return 'الشيخ\nصالح الفوزان';
    }
    if (fullName.contains('البدر')) {
      return 'الشيخ\nعبد الرزاق البدر';
    }
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0]}\n${parts[1]}';
    }
    return fullName;
  }

  /// فتح صفحة تفاصيل الشيخ وسيرته وشروحاته
  void _openSheikhDetails(BuildContext context, SheikhModel sheikh) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SheikhDetailsScreen(sheikh: sheikh),
      ),
    );
  }
}

/// رسام الزخرفة الإسلامية لغلاف الشيخ في وضع الشبكة
class _SheikhCardOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.patternBrown.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 16.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }

    // إطار داخلي رفيع
    final borderPaint = Paint()
      ..color = AppColors.accentGoldBeige.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
        const Radius.circular(10),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
