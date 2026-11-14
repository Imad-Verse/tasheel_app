import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_flavor.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import 'admin/admin_login_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة عن التطبيق ومن مشاريعنا (AboutAppScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تضم:
/// 1. شعار التطبيق التفاعلي (مجهز بعداد 5 ضغطات لفتح لوحة التحكم السرية).
/// 2. رسالة ورؤية تطبيق تسهيل المستمدة ديناميكياً من AppProvider.
/// 3. وسائل التواصل والمتابعة الرسمية المستمدة ديناميكياً من AppProvider.
/// 4. قسم "من مشاريعنا التقنية والعلمية" مع روابط الانتقال المستمدة ديناميكياً.
/// ═══════════════════════════════════════════════════════════════════════════
class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  // عداد الضغطات المتتالية على الشعار لفتح لوحة التحكم المخفية
  int _secretTapCount = 0;
  DateTime? _lastTapTime;

  void _handleLogoTap() {
    if (!kIsAdminBuild) return;
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!).inSeconds > 3) {
      _secretTapCount = 1;
    } else {
      _secretTapCount++;
    }
    _lastTapTime = now;

    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      if (kIsAdminBuild) {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AdminLoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح الرابط حالياً',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: AppColors.primaryDarkBrown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final aboutApp = appProvider.aboutApp;

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      body: Column(
        children: [
          // ── 1. الهيدر العلوي ─────────────────────────────────────────────
          _buildHeader(context),

          // ── 2. محتوى الصفحة ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── شعار التطبيق التفاعلي مع شارة رقم الإصدار ───────────
                  _buildInteractiveLogo(appProvider),

                  const SizedBox(height: 18),

                  // ── بطاقة وصف التطبيق ورسالته ───────────────────────────
                  _buildDescriptionCard(aboutApp),

                  const SizedBox(height: 18),

                  // ── وسائل التواصل والمتابعة ─────────────────────────────
                  _buildSocialChannelsSection(aboutApp),

                  if (aboutApp.projects.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    // ── قسم من مشاريعنا ───────────────────────────────────
                    _buildOurProjectsSection(aboutApp),
                  ],

                  const SizedBox(height: 24),

                  // ── قسم ادعمنا لمواصلة العطاء ───────────────────────────
                  _buildSupportSection(),
                ],
              ),
            ),
          ),
        ],
      ),
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
          IconButton(
            tooltip: 'رجوع',
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textGoldLight,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'عن التطبيق',
              style: GoogleFonts.readexPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  /// ── شعار التطبيق مع إطار زخرفي إسلامي وشارة رقم الإصدار ومستشعر ضغطات ─
  Widget _buildInteractiveLogo(AppProvider appProvider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _handleLogoTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentGoldBeige,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDarkBrown.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textGoldLight.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/icon.png',
                        fit: BoxFit.cover,
                        width: 104,
                        height: 104,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.primaryDarkBrown,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.auto_stories_rounded,
                                  color: AppColors.textGoldLight,
                                  size: 32,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'تسهيل',
                                  style: GoogleFonts.amiri(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textGoldLight,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Text(
                      'تسهيل',
                      style: TextStyle(color: Colors.transparent, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // شارة رقم الإصدار أسفل الشعار
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentGoldBeige.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDarkBrown.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.iconGold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'الإصدار ${appProvider.currentAppVersion}',
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDarkBrown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ── بطاقة وصف التطبيق ورسالته ──────────────────────────────────────────
  Widget _buildDescriptionCard(AboutAppModel aboutApp) {
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
          Text(
            'رسالة تطبيق تسهيل',
            style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDarkBrown,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 10),
          Text(
            aboutApp.appDescription,
            style: GoogleFonts.readexPro(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.8,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.iconGold, size: 16),
              const SizedBox(width: 6),
              Text(
                'وفق منهج أهل السنة والجماعة',
                style: GoogleFonts.readexPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iconGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ── وسائل التواصل والمتابعة ─────────────────────────────────────────────
  Widget _buildSocialChannelsSection(AboutAppModel aboutApp) {
    final channels = <Map<String, dynamic>>[];
    if (aboutApp.telegramUrl.trim().isNotEmpty) {
      channels.add({
        'title': 'تيليجرام',
        'icon': Icons.send_rounded,
        'url': aboutApp.telegramUrl.trim(),
      });
    }
    if (aboutApp.youtubeUrl.trim().isNotEmpty) {
      channels.add({
        'title': 'يوتيوب',
        'icon': Icons.play_circle_fill_rounded,
        'url': aboutApp.youtubeUrl.trim(),
      });
    }
    if (aboutApp.facebookUrl.trim().isNotEmpty) {
      channels.add({
        'title': 'فيسبوك',
        'icon': Icons.public_rounded,
        'url': aboutApp.facebookUrl.trim(),
      });
    }
    if (aboutApp.websiteUrl.trim().isNotEmpty) {
      channels.add({
        'title': 'الموقع الرسمي',
        'icon': Icons.language_rounded,
        'url': aboutApp.websiteUrl.trim(),
      });
    }

    if (channels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'قنوات التواصل والمتابعة',
          style: GoogleFonts.readexPro(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDarkBrown,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: channels.map((ch) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: AppColors.cardWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.dividerLight),
                  ),
                  child: InkWell(
                    onTap: () => _launchExternalUrl(ch['url'] as String),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ch['icon'] as IconData,
                            color: AppColors.iconGold,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ch['title'] as String,
                            style: GoogleFonts.readexPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// ── قسم من مشاريعنا ────────────────────────────────────────────────────
  Widget _buildOurProjectsSection(AboutAppModel aboutApp) {
    final projects = aboutApp.projects;
    if (projects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'من مشاريعنا التقنية والعلمية',
          style: GoogleFonts.readexPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDarkBrown,
          ),
        ),
        const SizedBox(height: 12),
        ...projects.map((proj) {
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // الأيقونة الرمزية على اليمين في RTL
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.iconGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // اسم المشروع
                      Expanded(
                        child: Text(
                          proj.title,
                          style: GoogleFonts.readexPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDarkBrown,
                          ),
                        ),
                      ),

                      // زر الانتقال على اليسار في RTL
                      if (proj.url.trim().isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _launchExternalUrl(proj.url),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: Text(
                            'انتقال',
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.scaffoldCream,
                            foregroundColor: AppColors.primaryDarkBrown,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: AppColors.accentGoldBeige),
                            ),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    proj.description,
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.textGoldLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'تم النسخ بنجاح',
                style: GoogleFonts.readexPro(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryDarkBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// ── قسم ادعمنا لمواصلة العطاء ──────────────────────────────────────────
  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accentGoldBeige.withValues(alpha: 0.8),
          width: 1.2,
        ),
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
          // 1. عنوان القسم مع الأيقونة
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: AppColors.iconGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ادعمنا لمواصلة العطاء',
                  style: GoogleFonts.readexPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDarkBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. الوصف القصير تحت العنوان
          Text(
            'دعمكم يساعدنا على تقديم المزيد جزاكم الله خيرا',
            style: GoogleFonts.readexPro(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // 3. حقول معلومات الدعم (قابلة للنسخ بضغطة زر)
          _buildSupportField(
            title: 'حساب CCP (داخل الجزائر)',
            value: '0024098927 clé 47',
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 10),
          _buildSupportField(
            title: 'الاسم',
            value: 'M. BAALOUL IMAD EDDINE',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 10),
          _buildSupportField(
            title: 'حساب بريدي موب (RIP)',
            value: '00799999002409892747',
            icon: Icons.credit_card_rounded,
          ),

          const SizedBox(height: 16),

          // 4. رسالة الشكر الختامية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.scaffoldCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentGoldBeige.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: AppColors.iconGold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'شكرًا لكل من دعم مشاريعي الصغيرة، سواء ماديًا أو معنويًا بالدعاء والتشجيع. أسأل الله أن يتقبل منكم جميعًا، ويجعلها في ميزان حسناتكم.',
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// حقل معلومات الدعم مع زر النسخ
  Widget _buildSupportField({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.scaffoldCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.dividerLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.iconGold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.readexPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    value,
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _copyToClipboard(value),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentGoldBeige,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
