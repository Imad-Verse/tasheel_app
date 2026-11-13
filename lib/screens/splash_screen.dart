import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../core/theme/app_colors.dart';
import 'main_scaffold.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة البداية (Splash Screen)
/// ═══════════════════════════════════════════════════════════════════════════
/// مطابقة للتصميم المرجعي:
/// - خلفية بنية داكنة مع زخرفة هندسية إسلامية خفيفة.
/// - إطار زخرفي إسلامي في المنتصف بداخله اسم التطبيق "تسهيل".
/// - نص "جميع الحقوق محفوظة لتطبيق تسهيل ©" في الأسفل.
/// - انتقال تلقائي بعد 2.5 ثانية بحركة Fade.
/// ═══════════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // إعداد الحركة
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // بدء الحركة
    _controller.forward();

    // الانتقال بعد 2.5 ثانية
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainScaffold(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDarkBrown,
      body: Stack(
        children: [
          // ── الزخرفة الهندسية في الخلفية ────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _SplashPatternPainter(),
            ),
          ),

          // ── المحتوى الرئيسي ────────────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── الإطار الزخرفي الإسلامي ─────────────────────────────
                  _buildIslamicFrame(),

                  const SizedBox(height: 24),

                  // ── الشعار النصي ─────────────────────────────────────────
                  Text(
                    'طريقك لتيسير العلوم الشرعية',
                    style: GoogleFonts.readexPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGoldLight.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // ── نص الحقوق في الأسفل ─────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // أيقونة/شعار صغير
                  Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.textGoldLight.withValues(alpha: 0.6),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'جميع الحقوق محفوظة لتطبيق تسهيل ©',
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGoldLight.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء الإطار الزخرفي الإسلامي مع اسم التطبيق
  Widget _buildIslamicFrame() {
    return SizedBox(
      width: 260,
      height: 280,
      child: CustomPaint(
        painter: _IslamicFramePainter(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'تسهيل',
              style: GoogleFonts.amiri(
                fontSize: 56,
                fontWeight: FontWeight.w700,
                color: AppColors.textGoldLight,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// رسام الزخرفة في خلفية شاشة البداية
/// ═══════════════════════════════════════════════════════════════════════════
class _SplashPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.patternBrown.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const spacing = 32.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        _drawGeometricUnit(canvas, Offset(x, y), spacing / 2, paint);
      }
    }
  }

  void _drawGeometricUnit(
      Canvas canvas, Offset center, double radius, Paint paint) {
    // رسم شكل هندسي ثماني
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 8;
      final x = center.dx + radius * 0.7 * math.cos(angle);
      final y = center.dy + radius * 0.7 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // خطوط داخلية للنجمة
    for (int i = 0; i < 4; i++) {
      final angle1 = (i * math.pi / 4);
      final angle2 = angle1 + math.pi;
      canvas.drawLine(
        Offset(
          center.dx + radius * 0.5 * math.cos(angle1),
          center.dy + radius * 0.5 * math.sin(angle1),
        ),
        Offset(
          center.dx + radius * 0.5 * math.cos(angle2),
          center.dy + radius * 0.5 * math.sin(angle2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// رسام الإطار الزخرفي الإسلامي (الشكل المحيط بالاسم)
/// ═══════════════════════════════════════════════════════════════════════════
/// يرسم شكلاً يجمع بين القوس الإسلامي (المدبب) في الأعلى
/// ودائرة مزخرفة في الأسفل، مع حد ذهبي.
/// ═══════════════════════════════════════════════════════════════════════════
class _IslamicFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.42;

    // ── الخلفية الداكنة للإطار ────────────────────────────────────────
    final bgPaint = Paint()
      ..color = AppColors.patternBrown.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // ── الحد الذهبي ──────────────────────────────────────────────────
    final borderPaint = Paint()
      ..color = AppColors.accentGoldBeige
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // رسم الشكل: دائرة مع قوس مدبب في الأعلى
    final framePath = Path();

    // نقطة القمة (الرأس المدبب)
    final topPointY = centerY - radius - 40;

    // بداية القوس الأيسر
    framePath.moveTo(centerX, topPointY);

    // القوس الأيسر من القمة إلى الدائرة
    framePath.quadraticBezierTo(
      centerX - radius * 0.7,
      centerY - radius * 0.6,
      centerX - radius,
      centerY + 10,
    );

    // الجزء السفلي (نصف دائرة)
    framePath.arcToPoint(
      Offset(centerX + radius, centerY + 10),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // القوس الأيمن من الدائرة إلى القمة
    framePath.quadraticBezierTo(
      centerX + radius * 0.7,
      centerY - radius * 0.6,
      centerX,
      topPointY,
    );

    framePath.close();

    // رسم الخلفية
    canvas.drawPath(framePath, bgPaint);

    // رسم زخرفة داخل الإطار
    _drawInnerPattern(canvas, Offset(centerX, centerY + 10), radius * 0.85);

    // رسم الحد الذهبي
    canvas.drawPath(framePath, borderPaint);

    // ── حلقة زخرفية صغيرة حول الإطار ─────────────────────────────────
    final decorPaint = Paint()
      ..color = AppColors.accentGoldBeige.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // رسم نقاط زخرفية صغيرة على الحد
    for (int i = 0; i < 24; i++) {
      final angle = (i * math.pi * 2 / 24);
      final dotX = centerX + (radius + 8) * math.cos(angle);
      final dotY = (centerY + 10) + (radius + 8) * math.sin(angle);
      canvas.drawCircle(Offset(dotX, dotY), 1.5, decorPaint);
    }
  }

  void _drawInnerPattern(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = AppColors.patternBrown.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // دوائر زخرفية داخلية
    canvas.drawCircle(center, radius * 0.9, paint);
    canvas.drawCircle(center, radius * 0.75, paint);

    // خطوط شعاعية
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      canvas.drawLine(
        Offset(
          center.dx + radius * 0.4 * math.cos(angle),
          center.dy + radius * 0.4 * math.sin(angle),
        ),
        Offset(
          center.dx + radius * 0.85 * math.cos(angle),
          center.dy + radius * 0.85 * math.sin(angle),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

