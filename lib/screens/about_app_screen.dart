import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!).inSeconds > 3) {
      _secretTapCount = 1;
    } else {
      _secretTapCount++;
    }
    _lastTapTime = now;

    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
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
                  // ── شعار التطبيق التفاعلي ────────────────────────────────
                  _buildInteractiveLogo(),

                  const SizedBox(height: 18),

                  // ── بطاقة وصف التطبيق ورسالته ───────────────────────────
                  _buildDescriptionCard(aboutApp),

                  const SizedBox(height: 18),

                  // ── وسائل التواصل والمتابعة ─────────────────────────────
                  _buildSocialChannelsSection(aboutApp),

                  const SizedBox(height: 24),

                  // ── قسم من مشاريعنا ─────────────────────────────────────
                  _buildOurProjectsSection(aboutApp),
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

  /// ── شعار التطبيق مع إطار زخرفي إسلامي ومستشعر ضغطات ───────────────────
  Widget _buildInteractiveLogo() {
    return Center(
      child: GestureDetector(
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
}
