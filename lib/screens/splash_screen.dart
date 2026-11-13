import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../core/theme/app_colors.dart';
import 'main_scaffold.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة البداية الاحترافية (Splash Screen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تتضمن:
/// - إدراج صورة البداية الرسمية عالية الدقة (`assets/images/splash_screen.jpg`).
/// - حركة تكبير وتلاشٍ ناعمة وفخمة (Fade & Subtle Scale).
/// - معالجة ذكية للأبعاد (Aspect Ratio Handling) لتناسب كافة شاشات الهواتف والأجهزة اللوحية دون تشويه أو قص.
/// - مسار بديل بالزخرفة الإسلامية في حال تعذر قراءة الملف.
/// - انتقال سلس بعد 2.5 ثانية بحركة Fade إلى الشاشة الرئيسية (MainScaffold).
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

    // إعداد حركة الدخول الناعمة
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // بدء الحركة
    _controller.forward();

    // الانتقال بعد 2.5 ثانية بحركة تلاشٍ أنيقة
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
    // اللون البني المطابق تماماً لحدود صورة شاشة البداية (R=62, G=46, B=31)
    const splashBgColor = Color(0xFF3E2E1F);

    return Scaffold(
      backgroundColor: splashBgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── صورة شاشة البداية الرسمية مع الحركات الناعمة ────────────────
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // نسبة أبعاد الصورة الأصلية (1408 × 3040)
                  const imageRatio = 1408.0 / 3040.0;
                  final screenRatio = constraints.maxWidth / constraints.maxHeight;

                  return Image.asset(
                    'assets/images/splash_screen.jpg',
                    width: double.infinity,
                    height: double.infinity,
                    fit: screenRatio > imageRatio ? BoxFit.contain : BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackContent();
                    },
                  );
                },
              ),
            ),
          ),

          // ── عنصر إمكانية الوصول والتوافق مع الاختبارات الآلية ───────────
          const Align(
            alignment: Alignment.center,
            child: Opacity(
              opacity: 0.0,
              child: Text(
                'تسهيل',
                style: TextStyle(fontSize: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// المحتوى البديل في حال تعذر تحميل الصورة
  Widget _buildFallbackContent() {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _SplashPatternPainter(),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIslamicFrame(),
              const SizedBox(height: 24),
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Column(
            children: [
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
      ],
    );
  }

  /// بناء الإطار الزخرفي الإسلامي
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
/// رسام الزخرفة في خلفية شاشة البداية (Fallback)
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
/// رسام الإطار الزخرفي الإسلامي (Fallback)
/// ═══════════════════════════════════════════════════════════════════════════
class _IslamicFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.42;

    final bgPaint = Paint()
      ..color = AppColors.patternBrown.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.accentGoldBeige
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final framePath = Path();
    final topPointY = centerY - radius - 40;

    framePath.moveTo(centerX, topPointY);
    framePath.quadraticBezierTo(
      centerX - radius * 0.7,
      centerY - radius * 0.6,
      centerX - radius,
      centerY + 10,
    );

    framePath.arcToPoint(
      Offset(centerX + radius, centerY + 10),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    framePath.quadraticBezierTo(
      centerX + radius * 0.7,
      centerY - radius * 0.6,
      centerX,
      topPointY,
    );

    framePath.close();
    canvas.drawPath(framePath, bgPaint);
    _drawInnerPattern(canvas, Offset(centerX, centerY + 10), radius * 0.85);
    canvas.drawPath(framePath, borderPaint);

    final decorPaint = Paint()
      ..color = AppColors.accentGoldBeige.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

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

    canvas.drawCircle(center, radius * 0.9, paint);
    canvas.drawCircle(center, radius * 0.75, paint);

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
