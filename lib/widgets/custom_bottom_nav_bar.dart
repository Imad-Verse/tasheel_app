import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// الشريط السفلي المخصص (Custom Bottom Navigation Bar)
/// ═══════════════════════════════════════════════════════════════════════════
/// مطابق للتصاميم المرجعية:
/// - خلفية بيضاء مع ظل خفيف علوي.
/// - 5 تبويبات من اليمين لليسار: الرئيسية، المتون، الشيوخ، المحفوظات، المزيد.
/// - التبويب النشط يظهر داخل كبسولة بيضاوية ذهبية مع نص.
/// - التبويبات غير النشطة تظهر كأيقونات فقط.
/// ═══════════════════════════════════════════════════════════════════════════
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.bottomNavBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              return _buildNavItem(
                index: index,
                icon: AppProvider.tabIcons[index],
                label: AppProvider.tabLabels[index],
                isSelected: currentIndex == index,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGoldBeige : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── النص (يظهر فقط عند التحديد) ────────────────────────────
            if (isSelected) ...[
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Readex Pro',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
            ],

            // ── الأيقونة ────────────────────────────────────────────────
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.inactiveTabIcon,
            ),
          ],
        ),
      ),
    );
  }
}

