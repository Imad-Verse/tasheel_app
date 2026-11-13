import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../core/theme/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/global_search_delegate.dart';
import 'lesson_player_screen.dart';
import 'notifications_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// الشاشة الرئيسية (HomeScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// مضبوطة بالكامل باتجاه اليمين إلى اليسار (RTL):
/// 1. هيدر بني داكن مزخرف: الترحيب واسم التطبيق على اليمين، أزرار البحث والإشعارات على اليسار.
/// 2. بطاقة "درر السلف" المتداخلة مع خلفية الهيدر.
/// 3. بطاقة "أكمل الاستماع" باتجاه RTL: الأيقونة على اليمين، النصوص بمحاذاة اليمين، والسهم على اليسار.
/// 4. بطاقة "المحفوظات" باتجاه RTL: الأيقونة على اليمين، النصوص بمحاذاة اليمين، والسهم على اليسار.
/// 5. بطاقة "إحصائيات الإنجاز" باتجاه RTL: العنوان بمحاذاة اليمين، والمربعات الثلاثة مرتبة من اليمين لليسار.
/// ═══════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 140.0;

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final quote = appProvider.currentQuote;
        final lastLesson = appProvider.lastPlayedLesson;
        final lastSeries = appProvider.lastPlayedSeries;

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Stack(
            children: [
              // ── 1. خلفية الهيدر البني الداكن المزخرف في الأعلى ─────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: headerHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDarkBrown,
                  ),
                  child: CustomPaint(
                    painter: _HomeHeaderPatternPainter(),
                  ),
                ),
              ),

              // ── 2. المحتوى القابل للتمرير ────────────────────────────────
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── شريط الهيدر العلوي (الترحيب على اليمين + الأزرار على اليسار) ──
                      _buildTopBar(context, appProvider),

                      const SizedBox(height: 18),

                      // ── بطاقة درر السلف (المتداخلة مع الهيدر) ───────────
                      _buildQuoteCard(context, quote, appProvider),

                      const SizedBox(height: 16),

                      // ── بطاقة الورد العلمي وسلسلة الاستمرارية ────────────
                      _buildDailyStudyGoalCard(context, appProvider),

                      const SizedBox(height: 16),

                      // ── بطاقة أكمل الاستماع (RTL: أيقونة يمين، نصوص يمين، سهم يسار) ──
                      _buildContinueListeningCard(
                        context,
                        seriesTitle: lastSeries?.title ?? 'شرح كتاب التوحيد',
                        lessonTitle: lastLesson?.title ?? 'الدرس الأول',
                        onTap: () {
                          if (lastLesson != null && lastSeries != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LessonPlayerScreen(
                                  lesson: lastLesson,
                                  series: lastSeries,
                                ),
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // ── بطاقة المحفوظات (RTL: أيقونة يمين، نصوص يمين، سهم يسار) ───
                      _buildBookmarksCard(
                        context,
                        studiedCount: appProvider.studiedSeriesCount,
                        onTap: () {
                          // الانتقال المباشر لتبويب المحفوظات (الفهرس 3)
                          appProvider.setCurrentTab(3);
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── بطاقة إحصائيات الإنجاز (RTL: العنوان يمين والمربعات من اليمين) ──
                      _buildStatsCard(appProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// شريط الهيدر العلوي: العنوان والترحيب على اليمين، وأزرار البحث والإشعارات على اليسار
  Widget _buildTopBar(BuildContext context, AppProvider appProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── 1. العنوان الترحيبي على اليمين في RTL ───────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, // في RTL يبدأ من اليمين
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تَسْهِيل',
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGoldLight,
                  height: 1.1,
                ),
              ),
              Text(
                'مرحبًا، يا طالب العلم',
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),

          // ── 2. أزرار الإجراءات على اليسار في RTL (البحث والإشعارات) ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderCircleButton(
                icon: Icons.search_rounded,
                tooltip: 'البحث الشامل',
                onTap: () => GlobalSearchDelegate.show(context),
              ),
              const SizedBox(width: 8),
              _buildHeaderCircleButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'الإشعارات والتنبيهات',
                badgeCount: appProvider.unreadNotificationsCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// زر دائري أنيق للهيدر مع شارة تنبيهية ذكية
  Widget _buildHeaderCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    int badgeCount = 0,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.patternBrown.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textGoldLight.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.textGoldLight,
                size: 22,
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                left: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryDarkBrown,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: GoogleFonts.readexPro(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// بطاقة "درر السلف" المتداخلة مع الهيدر
  Widget _buildQuoteCard(
    BuildContext context,
    Map<String, String> quote,
    AppProvider appProvider,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          appProvider.nextQuote();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // علامة الاقتباس العلوية على اليمين
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  '❝',
                  style: GoogleFonts.amiri(
                    fontSize: 32,
                    color: AppColors.accentGoldBeige,
                    height: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // نص المقولة بخط أميري أنيق وواضح
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  quote['text'] ?? '',
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // علامة الاقتباس السفلية
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '❞',
                  style: GoogleFonts.amiri(
                    fontSize: 32,
                    color: AppColors.accentGoldBeige,
                    height: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // اسم القائل مع خطوط ذهبية ناعمة
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 1.2,
                    color: AppColors.accentGoldBeige,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    quote['author'] ?? '',
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.iconGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 1.2,
                    color: AppColors.accentGoldBeige,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة "أكمل الاستماع" (من اليمين لليسار: أيقونة على اليمين، نصوص يمين، سهم على اليسار)
  Widget _buildContinueListeningCard(
    BuildContext context, {
    required String seriesTitle,
    required String lessonTitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── 1. الدائرة الذهبية والأيقونة في أقصى اليمين (في RTL) ────
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.headphones_rounded,
                  color: AppColors.iconGold,
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              // ── 2. النصوص التوضيحية في المنتصف بمحاذاة اليمين ───────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // في RTL يبدأ من اليمين
                  children: [
                    Text(
                      'أكمل الاستماع',
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$seriesTitle - $lessonTitle',
                      style: GoogleFonts.readexPro(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── 3. سهم التنقل في أقصى اليسار في RTL ─────────────────────
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.iconGold,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة "المحفوظات" (من اليمين لليسار: أيقونة على اليمين، نصوص يمين، سهم على اليسار)
  Widget _buildBookmarksCard(
    BuildContext context, {
    required int studiedCount,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── 1. الدائرة والأيقونة في أقصى اليمين (في RTL) ────────────
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.iconGold,
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              // ── 2. النصوص في المنتصف بمحاذاة اليمين ─────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // في RTL يبدأ من اليمين
                  children: [
                    Text(
                      'المحفوظات',
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'بدأت دراسة $studiedCount متون',
                      style: GoogleFonts.readexPro(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── 3. سهم التنقل في أقصى اليسار في RTL ─────────────────────
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.iconGold,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة "إحصائيات الإنجاز" بالمربعات الثلاثة مرتبة من اليمين لليسار
  Widget _buildStatsCard(AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // في RTL يبدأ العنوان من أقصى اليمين
        children: [
          Text(
            'إحصائيات الإنجاز',
            style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),
          // المربعات الثلاثة: تبدأ في RTL من اليمين: درس مكتمل -> متن منجز -> ساعة استماع
          Row(
            children: [
              _buildStatBox(
                number: '${appProvider.completedLessonsCount}',
                label: 'درس مكتمل',
              ),
              const SizedBox(width: 10),
              _buildStatBox(
                number: '${appProvider.completedSeriesCount}',
                label: 'متن منجز',
              ),
              const SizedBox(width: 10),
              _buildStatBox(
                number: '${appProvider.listeningHours}',
                label: 'ساعة استماع',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String number,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.scaffoldCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.dividerLight.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: GoogleFonts.readexPro(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.readexPro(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة "الورد العلمي اليومي" وسلسلة الاستمرارية (Streak)
  Widget _buildDailyStudyGoalCard(BuildContext context, AppProvider appProvider) {
    final progress = appProvider.dailyGoalProgress;
    final isCompleted = appProvider.isDailyGoalCompleted;
    final todayMinutes = appProvider.todayListeningMinutes;
    final targetMinutes = appProvider.dailyGoalMinutes;
    final streak = appProvider.streakCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
              : AppColors.accentGoldBeige.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── السطر العلوي: العنوان والشارة ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // العنوان مع أيقونة الكتاب على اليمين
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFE8F5E9)
                          : AppColors.accentGoldBeige.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.auto_stories_rounded,
                      color: isCompleted ? const Color(0xFF2E7D32) : AppColors.iconGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الورد العلمي اليومي',
                        style: GoogleFonts.readexPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'أحب العمل إلى الله أدومه وإن قل',
                        style: GoogleFonts.readexPro(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // شارة سلسلة الاستمرارية (Streak) على اليسار
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: streak > 0 ? const Color(0xFFFFF3E0) : AppColors.scaffoldCream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: streak > 0 ? const Color(0xFFFFB74D) : AppColors.dividerLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: streak > 0 ? const Color(0xFFE65100) : AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      streak > 0 ? '$streak أيام مداومة' : 'ابدأ المداومة',
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: streak > 0 ? const Color(0xFFBF360C) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── السطر الأوسط: أرقام الإنجاز والنسبة ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$todayMinutes',
                    style: GoogleFonts.readexPro(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? const Color(0xFF2E7D32) : AppColors.primaryDarkBrown,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'دقيقة من $targetMinutes د.',
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? const Color(0xFF2E7D32) : AppColors.iconGold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // شريط التقدم التفاعلي الأنيق
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.scaffoldCream,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? const Color(0xFF2E7D32) : AppColors.iconGold,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── السطر السفلي: حالة الإتمام وأزرار التخصيص ────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // حالة الإنجاز
              Expanded(
                child: Text(
                  isCompleted
                      ? '✨ تم إنجاز ورد اليوم بحمد الله'
                      : 'متبقي ${(targetMinutes - todayMinutes).clamp(0, targetMinutes)} دقيقة للإتمام',
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                    color: isCompleted ? const Color(0xFF2E7D32) : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // كبسولات التحكم السريعة (تعديل الهدف + وقت التذكير)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر وقت التذكير
                  InkWell(
                    onTap: () => _showReminderTimePicker(context, appProvider),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.dividerLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            appProvider.dailyReminderEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_outlined,
                            size: 13,
                            color: appProvider.dailyReminderEnabled
                                ? AppColors.iconGold
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appProvider.formattedDailyReminderTime,
                            style: GoogleFonts.readexPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDarkBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // زر تعديل الهدف
                  InkWell(
                    onTap: () => _showGoalPickerSheet(context, appProvider),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.dividerLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 13,
                            color: AppColors.iconGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'تعديل',
                            style: GoogleFonts.readexPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDarkBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// نافذة سفلية أنيقة لاختيار الهدف اليومي
  void _showGoalPickerSheet(BuildContext context, AppProvider appProvider) {
    const goals = [15, 30, 45, 60, 90];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.scaffoldCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.auto_stories_rounded, color: AppColors.iconGold, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'تحديد الورد العلمي اليومي',
                    style: GoogleFonts.readexPro(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDarkBrown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'اختر مدة الاستماع اليومية المناسبة لك لمواصلة طلب العلم:',
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: goals.map((minutes) {
                  final isSelected = appProvider.dailyGoalMinutes == minutes;
                  return InkWell(
                    onTap: () {
                      appProvider.setDailyGoalMinutes(minutes);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم ضبط وردك اليومي: $minutes دقيقة استماع',
                            style: GoogleFonts.readexPro(),
                          ),
                          backgroundColor: AppColors.primaryDarkBrown,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryDarkBrown : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryDarkBrown : AppColors.dividerLight,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.schedule_rounded,
                            size: 16,
                            color: isSelected ? AppColors.textGoldLight : AppColors.iconGold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$minutes دقيقة',
                            style: GoogleFonts.readexPro(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// نافذة اختيار وقت التذكير اليومي
  Future<void> _showReminderTimePicker(BuildContext context, AppProvider appProvider) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: appProvider.dailyReminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDarkBrown,
              onPrimary: AppColors.textGoldLight,
              surface: AppColors.scaffoldCream,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null && context.mounted) {
      await appProvider.setDailyReminderTime(pickedTime);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم ضبط موعد التذكير اليومي عند ${appProvider.formattedDailyReminderTime}',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: AppColors.primaryDarkBrown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// رسام زخرفة الهيدر العلوي
class _HomeHeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.patternBrown.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const spacing = 26.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawStar(canvas, Offset(x, y), spacing / 2, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(c.dx + r * 0.3 * math.cos(a), c.dy + r * 0.3 * math.sin(a)),
        Offset(c.dx + r * 0.65 * math.cos(a), c.dy + r * 0.65 * math.sin(a)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
