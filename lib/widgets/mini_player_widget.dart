import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/audio_provider.dart';
import '../screens/lesson_player_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// المشغل المصغر العائم (MiniPlayerWidget)
/// ═══════════════════════════════════════════════════════════════════════════
/// يظهر فوق الشريط السفلي مباشرة عندما يكون هناك درس قيد التشغيل أو الإيقاف:
/// - شريط تقدم رفيع أعلى المشغل.
/// - عنوان الدرس، اسم الشيخ.
/// - زر التشغيل / الإيقاف المؤقت.
/// - زر الإغلاق (X) لإخفاء المشغل المصغر.
/// - النقر على المشغل يفتح شاشة مشغل الدرس الكاملة (LessonPlayerScreen).
/// ═══════════════════════════════════════════════════════════════════════════
class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (!audioProvider.showMiniPlayer || audioProvider.currentLesson == null) {
          return const SizedBox.shrink();
        }

        final lesson = audioProvider.currentLesson!;
        final series = audioProvider.currentSeries!;
        final sheikh = audioProvider.currentSheikh;

        // حساب نسبة التقدم
        final totalMs = audioProvider.totalDuration.inMilliseconds;
        final currentMs = audioProvider.currentPosition.inMilliseconds;
        final progress = (totalMs > 0) ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentGoldBeige.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. شريط التقدم الرفيع في الأعلى ─────────────────────
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.5,
                  backgroundColor: AppColors.dividerLight.withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGoldBeige),
                ),

                // ── 2. محتوى المشغل المصغر ──────────────────────────────
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonPlayerScreen(
                            lesson: lesson,
                            series: series,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          // زر الإغلاق على اليسار في RTL
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            tooltip: 'إغلاق المشغل',
                            onPressed: () {
                              audioProvider.closeMiniPlayer();
                            },
                          ),

                          // زر التشغيل والإيقاف المؤقت
                          InkWell(
                            onTap: () {
                              audioProvider.togglePlayPause();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.accentGoldBeige,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentGoldBeige.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                audioProvider.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppColors.textPrimary,
                                size: 24,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // نصوص الدرس والشيخ
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  lesson.title,
                                  style: GoogleFonts.readexPro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sheikh?.name ?? series.title,
                                  style: GoogleFonts.readexPro(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // أيقونة سماعات / غلاف مصغر
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryDarkBrown,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.headphones_rounded,
                              color: AppColors.textGoldLight,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
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

