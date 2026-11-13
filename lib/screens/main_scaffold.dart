import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
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
/// ═══════════════════════════════════════════════════════════════════════════
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  /// قائمة الصفحات الخمسة
  static const List<Widget> _screens = [
    HomeScreen(),
    CategoriesScreen(),
    SheikhsScreen(),
    BookmarksScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
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
