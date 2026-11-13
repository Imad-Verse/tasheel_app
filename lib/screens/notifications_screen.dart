import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/decorated_header.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة الإشعارات (NotificationsScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تعرض الإشعارات والتنبيهات الحية للمستخدمين:
/// - هيدر بني مزخرف مع زر "تحديد الكل كمقروء" وزر رجوع.
/// - تمييز الإشعار غير المقروء بنقطة وإطار ذهبي.
/// - أيقونات مخصصة حسب نوع الإشعار (شيخ، درس، تفريغ، تحديث، عام).
/// - زر مباشر لتحميل التحديث عبر url_launcher إذا كان الإشعار تحديثاً أو يتضمن رابط إجراء.
/// ═══════════════════════════════════════════════════════════════════════════
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'sheikh':
        return Icons.people_alt_rounded;
      case 'lesson':
        return Icons.audiotrack_rounded;
      case 'transcript':
        return Icons.subtitles_rounded;
      case 'update':
        return Icons.system_update_rounded;
      case 'general':
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconBgColor(String type) {
    switch (type) {
      case 'update':
        return AppColors.primaryDarkBrown;
      case 'transcript':
        return const Color(0xFF2E5A44);
      case 'lesson':
        return const Color(0xFF5A442E);
      case 'sheikh':
        return const Color(0xFF4A3525);
      default:
        return AppColors.primaryDarkBrown;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else {
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _handleActionUrl(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح الرابط: $url', style: GoogleFonts.readexPro()),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final notifications = appProvider.notifications;
        final unreadCount = appProvider.unreadNotificationsCount;

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── هيدر الصفحة المزخرف ────────────────────────────────────
              DecoratedHeader(
                title: 'الإشعارات',
                showSearchIcon: false,
                actions: [
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: () => appProvider.markAllNotificationsAsRead(),
                      icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.textGoldLight),
                      label: Text(
                        'تحديد الكل كمقروء',
                        style: GoogleFonts.readexPro(
                          color: AppColors.textGoldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.patternBrown.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: AppColors.textGoldLight.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'رجوع',
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textGoldLight,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // ── قائمة الإشعارات ─────────────────────────────────────────
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.dividerLight),
                              ),
                              child: const Icon(
                                Icons.notifications_off_outlined,
                                size: 54,
                                color: AppColors.goldMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد إشعارات حتى الآن',
                              style: GoogleFonts.readexPro(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDarkBrown,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ستصلك إشعارات وتنبيهات فور إضافة دروس أو شروحات جديدة',
                              style: GoogleFonts.readexPro(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        itemCount: notifications.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final notif = notifications[index];
                          final isUnread = !appProvider.isNotificationRead(notif.id);
                          final hasActionUrl = notif.actionUrl != null && notif.actionUrl!.trim().isNotEmpty;
                          final isUpdate = notif.type == 'update';

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                appProvider.markNotificationAsRead(notif.id);
                                if (hasActionUrl) {
                                  _handleActionUrl(context, notif.actionUrl);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isUnread
                                        ? AppColors.iconGold
                                        : AppColors.dividerLight,
                                    width: isUnread ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isUnread
                                          ? AppColors.iconGold.withValues(alpha: 0.12)
                                          : Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // أيقونة نوع الإشعار
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: _getIconBgColor(notif.type),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.iconGold.withValues(alpha: 0.4),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            _getIconForType(notif.type),
                                            color: AppColors.iconGold,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // العنوان ووقت الإرسال
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      notif.title,
                                                      style: GoogleFonts.readexPro(
                                                        fontSize: 14,
                                                        fontWeight: isUnread
                                                            ? FontWeight.bold
                                                            : FontWeight.w600,
                                                        color: AppColors.primaryDarkBrown,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isUnread) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.iconGold,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatDate(notif.createdAt),
                                                style: GoogleFonts.readexPro(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    // نص الإشعار
                                    Text(
                                      notif.body,
                                      style: GoogleFonts.readexPro(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),

                                    // زر تحميل التحديث أو فتح الرابط إن وُجد
                                    if (hasActionUrl || isUpdate) ...[
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            appProvider.markNotificationAsRead(notif.id);
                                            _handleActionUrl(context, notif.actionUrl);
                                          },
                                          icon: Icon(
                                            isUpdate
                                                ? Icons.download_rounded
                                                : Icons.open_in_new_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            isUpdate
                                                ? 'تحميل التحديث الآن'
                                                : 'فتح الرابط المرفق',
                                            style: GoogleFonts.readexPro(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryDarkBrown,
                                            foregroundColor: AppColors.textGoldLight,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              side: const BorderSide(color: AppColors.iconGold, width: 0.8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
