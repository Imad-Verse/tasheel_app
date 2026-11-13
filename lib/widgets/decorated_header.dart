import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../core/theme/app_colors.dart';
import 'global_search_delegate.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// الهيدر البني المزخرف العلوي (DecoratedHeader)
/// ═══════════════════════════════════════════════════════════════════════════
/// يُستخدم في أعلى الشاشات الرئيسية (المتون، الشيوخ، المحفوظات...).
/// يحتوي على:
/// - خلفية بنية داكنة مع زخرفة إسلامية هندسية مرسومة يدوياً.
/// - عنوان الصفحة باللون الأبيض أو الذهبي بخط Readex Pro.
/// - زر البحث الدائري وزر الإجراءات الإضافية.
/// ═══════════════════════════════════════════════════════════════════════════
class DecoratedHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final double? height;
  final bool showSearchIcon;
  final VoidCallback? onSearchPressed;
  final Widget? customTitleWidget;

  const DecoratedHeader({
    super.key,
    required this.title,
    this.actions,
    this.height,
    this.showSearchIcon = true,
    this.onSearchPressed,
    this.customTitleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final totalHeight = height ?? (topPadding + 70);

    return Container(
      width: double.infinity,
      height: totalHeight,
      decoration: const BoxDecoration(
        color: AppColors.primaryDarkBrown,
      ),
      child: Stack(
        children: [
          // ── الزخرفة الهندسية في الخلفية ──────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _IslamicPatternPainter(),
            ),
          ),

          // ── المحتوى ─────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // عنوان الصفحة على اليمين في RTL
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: customTitleWidget ??
                          Text(
                            title,
                            style: GoogleFonts.readexPro(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // أيقونات الإجراءات (بحث، رجوع...) على اليسار في RTL
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showSearchIcon)
                        _buildActionButton(
                          icon: Icons.search_rounded,
                          onTap: onSearchPressed ?? () => GlobalSearchDelegate.show(context),
                          tooltip: 'بحث شامل',
                        ),
                      ...?actions,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.patternBrown.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.textGoldLight.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.textGoldLight,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// رسام الزخرفة الهندسية الإسلامية للهيدر
/// ═══════════════════════════════════════════════════════════════════════════
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.patternBrown.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 28.0;

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        _drawStarPattern(canvas, Offset(x, y), spacing / 2, paint);
      }
    }
  }

  void _drawStarPattern(
      Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final outerX = center.dx + radius * 0.8 * math.cos(angle);
      final outerY = center.dy + radius * 0.8 * math.sin(angle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      }

      final nextAngle = ((i + 1) * math.pi / 4);
      final innerAngle = angle + math.pi / 8;
      final innerX = center.dx + radius * 0.4 * math.cos(innerAngle);
      final innerY = center.dy + radius * 0.4 * math.sin(innerAngle);
      final nextOuterX = center.dx + radius * 0.8 * math.cos(nextAngle);
      final nextOuterY = center.dy + radius * 0.8 * math.sin(nextAngle);

      path.lineTo(innerX, innerY);
      path.lineTo(nextOuterX, nextOuterY);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
