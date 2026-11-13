import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/mini_player_widget.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'sheikhs_screen.dart';
import 'bookmarks_screen.dart';
import 'more_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// الهيكل الرئيسي للتطبيق (Main Scaffold)
/// ═══════════════════════════════════════════════════════════════════════════
/// يحتوي على:
/// - IndexedStack لعرض الصفحات الخمسة مع الحفاظ على حالتها أثناء التنقل.
/// - شريط التنقل السفلي المخصص (CustomBottomNavBar).
/// - الفحص التلقائي الفوري لتحديثات التطبيق وإظهار نافذة التحديث عند توفره.
/// ═══════════════════════════════════════════════════════════════════════════
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  bool _hasShownUpdateDialog = false;

  /// قائمة الصفحات الخمسة
  static const List<Widget> _screens = [
    HomeScreen(),
    CategoriesScreen(),
    SheikhsScreen(),
    BookmarksScreen(),
    MoreScreen(),
  ];

  void _showUpdateDialog(BuildContext context, AppUpdateModel updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (ctx) => PopScope(
        canPop: !updateInfo.isForceUpdate,
        child: AlertDialog(
          backgroundColor: AppColors.scaffoldCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.iconGold, width: 1.5),
          ),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkBrown,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.iconGold, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.iconGold,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'يتوفر تحديث جديد لتطبيق تسهيل (${updateInfo.latestVersion})',
                style: GoogleFonts.readexPro(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkBrown,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (updateInfo.releaseNotes.trim().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dividerLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مميزات التحديث الجديد:',
                        style: GoogleFonts.readexPro(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDarkBrown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        updateInfo.releaseNotes.trim(),
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, color: AppColors.textGoldLight),
                label: Text(
                  'تحميل التحديث الآن',
                  style: GoogleFonts.readexPro(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkBrown,
                  foregroundColor: AppColors.textGoldLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.iconGold, width: 1),
                  ),
                ),
                onPressed: () async {
                  if (updateInfo.downloadUrl.trim().isNotEmpty) {
                    try {
                      final uri = Uri.parse(updateInfo.downloadUrl.trim());
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        await launchUrl(uri);
                      }
                    } catch (_) {}
                  }
                  if (!updateInfo.isForceUpdate && ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
              ),
              if (!updateInfo.isForceUpdate) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'لاحقاً',
                    style: GoogleFonts.readexPro(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // فحص توفر التحديث وعرض النافذة الحوارية لمرة واحدة عند الاكتشاف
        if (appProvider.isUpdateAvailable && !_hasShownUpdateDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && appProvider.isUpdateAvailable && !_hasShownUpdateDialog) {
              _hasShownUpdateDialog = true;
              _showUpdateDialog(context, appProvider.appUpdateInfo);
            }
          });
        }

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: IndexedStack(
            index: appProvider.currentTabIndex,
            children: _screens,
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayerWidget(),
              CustomBottomNavBar(
                currentIndex: appProvider.currentTabIndex,
                onTabSelected: (index) {
                  appProvider.setCurrentTab(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
