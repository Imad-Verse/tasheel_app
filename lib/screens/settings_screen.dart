import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة إعدادات التطبيق (SettingsScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تتيح تعديل اسم طالب العلم، والتحكم بحجم خط التفريغ الافتراضي،
/// والتشغيل التلقائي، ومسح الذاكرة المؤقتة.
/// ═══════════════════════════════════════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _nameController = TextEditingController(text: appProvider.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر العلوي المزخرف ─────────────────────────────────
              _buildHeader(context),

              // ── 2. محتوى الإعدادات ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── بطاقة اسم طالب العلم ─────────────────────────────
                      _buildUserNameCard(context, appProvider),

                      const SizedBox(height: 16),

                      // ── بطاقة خط التفريغ النصي ───────────────────────────
                      _buildFontSizeCard(context, appProvider),

                      const SizedBox(height: 16),

                      // ── بطاقة مشغل الصوتيات ──────────────────────────────
                      _buildAudioPlayerSettingsCard(context, appProvider),

                      const SizedBox(height: 16),

                      // ── بطاقة الذاكرة المؤقتة ────────────────────────────
                      _buildCacheSettingsCard(context, appProvider),

                      const SizedBox(height: 16),

                      // ── بطاقة الإصدار والمعلومات ─────────────────────────
                      _buildAppInfoCard(),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 12,
        right: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDarkBrown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(
            child: Text(
              'إعدادات التطبيق',
              style: GoogleFonts.readexPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            tooltip: 'رجوع',
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textGoldLight,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// بطاقة تعديل اسم طالب العلم
  Widget _buildUserNameCard(BuildContext context, AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Spacer(),
              Text(
                'اسمك يا طالب العلم',
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.person_rounded, color: AppColors.iconGold, size: 22),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'الاسم الذي يظهر في الترحيب والملف التعريفي داخل التطبيق:',
            style: GoogleFonts.readexPro(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('student_name_field'),
            controller: _nameController,
            textAlign: TextAlign.right,
            style: GoogleFonts.readexPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDarkBrown,
            ),
            decoration: InputDecoration(
              hintText: 'أدخل اسمك أو كنيتك...',
              hintStyle: GoogleFonts.readexPro(fontSize: 13, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.scaffoldCream,
              prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.iconGold, size: 22),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.dividerLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.dividerLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryDarkBrown, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            key: const ValueKey('save_student_name_button'),
            onPressed: () {
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                FocusScope.of(context).unfocus();
                appProvider.setUserName(newName);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم حفظ الاسم بنجاح: $newName',
                      style: GoogleFonts.readexPro(),
                    ),
                    backgroundColor: AppColors.primaryDarkBrown,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(
              'حفظ الاسم',
              style: GoogleFonts.readexPro(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGoldBeige,
              foregroundColor: AppColors.primaryDarkBrown,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة حجم خط التفريغ النصي مع معاينة مباشرة
  Widget _buildFontSizeCard(BuildContext context, AppProvider appProvider) {
    final sizes = [14.0, 16.0, 18.0, 20.0, 22.0];
    final currentSize = appProvider.defaultTranscriptFontSize;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Spacer(),
              Text(
                'حجم خط التفريغ الافتراضي',
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.format_size_rounded, color: AppColors.iconGold, size: 22),
            ],
          ),
          const SizedBox(height: 14),

          // خيارات الأحجام
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: sizes.map((sz) {
              final isSelected = (currentSize - sz).abs() < 0.5;
              return InkWell(
                onTap: () => appProvider.setDefaultTranscriptFontSize(sz),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryDarkBrown : AppColors.scaffoldCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryDarkBrown : AppColors.dividerLight,
                    ),
                  ),
                  child: Text(
                    '${sz.toInt()}',
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // صندوق المعاينة الحية
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.scaffoldCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dividerLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'معاينة الخط:',
                  style: GoogleFonts.readexPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iconGold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ • الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى نَبِيِّنَا مُحَمَّدٍ.',
                  style: GoogleFonts.amiri(
                    fontSize: currentSize,
                    height: 1.9,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة إعدادات مشغل الصوت
  Widget _buildAudioPlayerSettingsCard(BuildContext context, AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Spacer(),
              Text(
                'مشغل الصوتيات',
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.music_note_rounded, color: AppColors.iconGold, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                value: appProvider.autoPlayNextLesson,
                activeThumbColor: AppColors.accentGoldBeige,
                activeTrackColor: AppColors.primaryDarkBrown,
                onChanged: (val) => appProvider.setAutoPlayNextLesson(val),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'التشغيل التلقائي للدرس التالي',
                    style: GoogleFonts.readexPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'الانتقال للدرس اللاحق فور اكتمال الاستماع',
                    style: GoogleFonts.readexPro(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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

  /// بطاقة الذاكرة المؤقتة
  Widget _buildCacheSettingsCard(BuildContext context, AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Spacer(),
              Text(
                'التخزين والذاكرة المؤقتة',
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.cleaning_services_rounded, color: AppColors.iconGold, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'حذف الملفات المؤقتة المخزنة لتسريع التطبيق واسترجاع مساحة التخزين.',
            style: GoogleFonts.readexPro(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              appProvider.clearCache();
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم مسح الذاكرة المؤقتة بنجاح',
                    style: GoogleFonts.readexPro(),
                  ),
                  backgroundColor: AppColors.primaryDarkBrown,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.delete_sweep_rounded, size: 18),
            label: Text(
              'مسح الذاكرة المؤقتة',
              style: GoogleFonts.readexPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDarkBrown,
              side: const BorderSide(color: AppColors.dividerLight),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة الإصدار
  Widget _buildAppInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            'تطبيق تسهيل • الإصدار 1.0.0 (بناء 1)',
            style: GoogleFonts.readexPro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'جميع الحقوق محفوظة لتطبيق تسهيل © 2026',
            style: GoogleFonts.readexPro(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
