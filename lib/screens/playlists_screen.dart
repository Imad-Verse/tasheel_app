import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/audio_provider.dart';
import '../services/mock_data_service.dart';
import 'lesson_player_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة قوائم التشغيل والمجموعات العلمية (PlaylistsScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تتيح لطالب العلم تنظيم مدارسته وحفظه عبر مجموعات مخصصة مع إمكانية:
/// - إنشاء قوائم تشغيل مخصصة مع اسم ووصف.
/// - إضافة وإزالة الدروس وإعادة ترتيبها بالسحب والإفلات.
/// - التشغيل المتتابع التلقائي لكافة دروس القائمة.
/// ═══════════════════════════════════════════════════════════════════════════
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, AudioProvider>(
      builder: (context, appProvider, audioProvider, child) {
        final playlists = appProvider.playlists;

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر العلوي المزخرف ─────────────────────────────────
              _buildHeader(context, appProvider, playlists.length),

              // ── 2. المحتوى ───────────────────────────────────────────────
              Expanded(
                child: playlists.isEmpty
                    ? _buildEmptyState(context, appProvider)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        physics: const BouncingScrollPhysics(),
                        itemCount: playlists.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          final playlistLessons =
                              appProvider.getLessonsForPlaylist(playlist);

                          return _buildPlaylistCard(
                            context: context,
                            playlist: playlist,
                            playlistLessons: playlistLessons,
                            appProvider: appProvider,
                            audioProvider: audioProvider,
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

  /// الهيدر العلوي البني المزخرف مع زر الإضافة
  Widget _buildHeader(
    BuildContext context,
    AppProvider appProvider,
    int totalCount,
  ) {
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
          // زر الرجوع في RTL
          IconButton(
            tooltip: 'رجوع',
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textGoldLight,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),

          // العنوان في المنتصف
          Expanded(
            child: Text(
              'قوائم التشغيل والمجموعات',
              style: GoogleFonts.readexPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // زر إضافة قائمة تشغيل جديدة
          IconButton(
            tooltip: 'إنشاء قائمة جديدة',
            icon: const Icon(
              Icons.playlist_add_rounded,
              color: AppColors.textGoldLight,
              size: 26,
            ),
            onPressed: () => _openCreatePlaylistDialog(context, appProvider),
          ),
        ],
      ),
    );
  }

  /// بطاقة قائمة التشغيل
  Widget _buildPlaylistCard({
    required BuildContext context,
    required CustomPlaylistModel playlist,
    required List<LessonModel> playlistLessons,
    required AppProvider appProvider,
    required AudioProvider audioProvider,
  }) {
    final bool isCurrentActive =
        audioProvider.isPlaylistMode &&
        audioProvider.activePlaylist?.id == playlist.id;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentActive
                ? AppColors.primaryDarkBrown
                : AppColors.dividerLight,
            width: isCurrentActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة المجلد / القائمة
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCurrentActive
                        ? AppColors.primaryDarkBrown
                        : AppColors.accentGoldBeige.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentGoldBeige.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    Icons.featured_play_list_rounded,
                    color: isCurrentActive
                        ? AppColors.textGoldLight
                        : AppColors.primaryDarkBrown,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // تفاصيل القائمة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        style: GoogleFonts.readexPro(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (playlist.description != null &&
                          playlist.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          playlist.description!,
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // قائمة الخيارات الإضافية (تعديل / حذف)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openEditPlaylistDialog(context, appProvider, playlist);
                    } else if (val == 'delete') {
                      _confirmDeletePlaylist(context, appProvider, playlist);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('تعديل القائمة', style: GoogleFonts.readexPro()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'حذف القائمة',
                            style: GoogleFonts.readexPro(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.dividerLight, height: 1),
            const SizedBox(height: 10),

            // السطر السفلي: عدد الدروس وزر التشغيل التلقائي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.audiotrack_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${playlistLessons.length} دروس',
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isCurrentActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkBrown,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'قيد التشغيل الآن',
                          style: GoogleFonts.readexPro(
                            fontSize: 10,
                            color: AppColors.textGoldLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                if (playlistLessons.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      audioProvider.startPlaylistPlayback(
                        playlist: playlist,
                        playlistLessons: playlistLessons,
                        startIndex: 0,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'بدأ تشغيل قائمة "${playlist.title}" بالتتابع',
                            style: GoogleFonts.readexPro(),
                          ),
                          backgroundColor: AppColors.primaryDarkBrown,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(
                      'تشغيل الكل',
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkBrown,
                      foregroundColor: AppColors.textGoldLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// الحالة الفارغة عند عدم وجود قوائم
  Widget _buildEmptyState(BuildContext context, AppProvider appProvider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentGoldBeige.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.playlist_add_rounded,
                size: 40,
                color: AppColors.primaryDarkBrown,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'لا توجد قوائم تشغيل مخصصة',
              style: GoogleFonts.readexPro(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك تجميع الدروس والشروحات التي ترغب في مدارستها وتكرارها معاً في قوائم مخصصة تعمل بالتتابع التلقائي.',
              style: GoogleFonts.readexPro(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () => _openCreatePlaylistDialog(context, appProvider),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'إنشاء أول قائمة تشغيل',
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkBrown,
                foregroundColor: AppColors.textGoldLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// نافذة إنشاء قائمة جديدة
  void _openCreatePlaylistDialog(
    BuildContext context,
    AppProvider appProvider,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'إنشاء قائمة تشغيل جديدة',
          style: GoogleFonts.readexPro(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDarkBrown,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'عنوان القائمة *',
                  hintText: 'مثال: مراجعة أصول الإيمان',
                  labelStyle: GoogleFonts.readexPro(),
                  hintStyle: GoogleFonts.readexPro(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'وصف اختياري',
                  hintText: 'وصف مختصر لأهداف القائمة العلمية...',
                  labelStyle: GoogleFonts.readexPro(),
                  hintStyle: GoogleFonts.readexPro(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.readexPro()),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              await appProvider.createPlaylist(
                title: title,
                description: descController.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم إنشاء قائمة "$title" بنجاح',
                      style: GoogleFonts.readexPro(),
                    ),
                    backgroundColor: AppColors.primaryDarkBrown,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkBrown,
              foregroundColor: AppColors.textGoldLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'إنشاء',
              style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      descController.dispose();
    });
  }

  /// نافذة تعديل اسم ووصف قائمة
  void _openEditPlaylistDialog(
    BuildContext context,
    AppProvider appProvider,
    CustomPlaylistModel playlist,
  ) {
    final titleController = TextEditingController(text: playlist.title);
    final descController = TextEditingController(text: playlist.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'تعديل قائمة التشغيل',
          style: GoogleFonts.readexPro(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDarkBrown,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان القائمة',
                  labelStyle: GoogleFonts.readexPro(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'وصف القائمة',
                  labelStyle: GoogleFonts.readexPro(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.readexPro()),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              if (newTitle.isEmpty) return;
              Navigator.pop(ctx);
              await appProvider.renamePlaylist(
                playlist.id,
                newTitle,
                descController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkBrown,
              foregroundColor: AppColors.textGoldLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'حفظ',
              style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      descController.dispose();
    });
  }

  /// تأكيد حذف قائمة
  void _confirmDeletePlaylist(
    BuildContext context,
    AppProvider appProvider,
    CustomPlaylistModel playlist,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'حذف قائمة التشغيل؟',
          style: GoogleFonts.readexPro(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDarkBrown,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف قائمة "${playlist.title}"؟ لن يتم حذف الدروس نفسها من التطبيق.',
          style: GoogleFonts.readexPro(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.readexPro()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await appProvider.deletePlaylist(playlist.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// ═════════════════════════════════════════════════════════════════════════
  /// النافذة السفلية لإضافة درس لقائمة تشغيل (Bottom Sheet)
  /// ═════════════════════════════════════════════════════════════════════════
  static void showAddToPlaylistBottomSheet(
    BuildContext context,
    LessonModel lesson,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddToPlaylistBottomSheetContent(lesson: lesson),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// محتوى النافذة السفلية لإضافة درس إلى قوائم التشغيل
/// ═══════════════════════════════════════════════════════════════════════════
class _AddToPlaylistBottomSheetContent extends StatefulWidget {
  final LessonModel lesson;
  const _AddToPlaylistBottomSheetContent({required this.lesson});

  @override
  State<_AddToPlaylistBottomSheetContent> createState() =>
      _AddToPlaylistBottomSheetContentState();
}

class _AddToPlaylistBottomSheetContentState
    extends State<_AddToPlaylistBottomSheetContent> {
  final TextEditingController _newPlaylistController = TextEditingController();
  bool _isCreatingNew = false;

  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final playlists = appProvider.playlists;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // مقبض السحب
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
          const SizedBox(height: 14),

          // العنوان
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.playlist_add_rounded,
                    color: AppColors.primaryDarkBrown,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إضافة إلى قائمة تشغيل',
                    style: GoogleFonts.readexPro(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDarkBrown,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          Text(
            widget.lesson.title,
            style: GoogleFonts.readexPro(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.dividerLight, height: 1),
          const SizedBox(height: 12),

          // حقل إنشاء قائمة جديدة سريعة
          if (_isCreatingNew) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newPlaylistController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'اسم القائمة الجديدة...',
                      hintStyle: GoogleFonts.readexPro(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final title = _newPlaylistController.text.trim();
                    if (title.isEmpty) return;
                    final created = await appProvider.createPlaylist(title: title);
                    await appProvider.addLessonToPlaylist(
                      created.id,
                      widget.lesson.id,
                    );
                    setState(() {
                      _isCreatingNew = false;
                      _newPlaylistController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkBrown,
                    foregroundColor: AppColors.textGoldLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('إنشاء وإضافة', style: GoogleFonts.readexPro()),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            OutlinedButton.icon(
              onPressed: () => setState(() => _isCreatingNew = true),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                '+ إنشاء قائمة تشغيل جديدة',
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accentGoldBeige),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // قائمة القوائم الحالية مع خيار الاختيار
          if (playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'لا توجد قوائم بعد، أنشئ أول قائمة بالأعلى.',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final p = playlists[index];
                  final isAdded = p.lessonIds.contains(widget.lesson.id);

                  return CheckboxListTile(
                    value: isAdded,
                    activeColor: AppColors.primaryDarkBrown,
                    checkColor: AppColors.textGoldLight,
                    title: Text(
                      p.title,
                      style: GoogleFonts.readexPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${p.lessonIds.length} دروس',
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onChanged: (val) async {
                      if (isAdded) {
                        await appProvider.removeLessonFromPlaylist(
                          p.id,
                          widget.lesson.id,
                        );
                      } else {
                        await appProvider.addLessonToPlaylist(
                          p.id,
                          widget.lesson.id,
                        );
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة تفاصيل قائمة التشغيل وإعادة ترتيب دروسها بالسحب والإفلات
/// ═══════════════════════════════════════════════════════════════════════════
class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, AudioProvider>(
      builder: (context, appProvider, audioProvider, child) {
        final playlist = appProvider.getPlaylistById(playlistId);
        if (playlist == null) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldCream,
            body: Center(
              child: Text(
                'القائمة غير موجودة أو تم حذفها',
                style: GoogleFonts.readexPro(),
              ),
            ),
          );
        }

        final lessons = appProvider.getLessonsForPlaylist(playlist);
        final bool isCurrentActive =
            audioProvider.isPlaylistMode &&
            audioProvider.activePlaylist?.id == playlist.id;

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // الهيدر
              _buildDetailHeader(context, playlist),

              // بطاقة تشغيل القائمة وإحصائياتها
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الدروس (${lessons.length}) • اسحب لإعادة الترتيب',
                      style: GoogleFonts.readexPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (lessons.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () {
                          audioProvider.startPlaylistPlayback(
                            playlist: playlist,
                            playlistLessons: lessons,
                            startIndex: 0,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'بدأ تشغيل قائمة "${playlist.title}" بالتتابع',
                                style: GoogleFonts.readexPro(),
                              ),
                              backgroundColor: AppColors.primaryDarkBrown,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(
                          isCurrentActive ? 'إعادة التشغيل' : 'تشغيل الكل',
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDarkBrown,
                          foregroundColor: AppColors.textGoldLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // قائمة الدروس مع ReorderableListView
              Expanded(
                child: lessons.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد دروس في هذه القائمة بعد.\nأضف الدروس من خلال زر "إضافة لقائمة" داخل مشغل أي درس.',
                          style: GoogleFonts.readexPro(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        itemCount: lessons.length,
                        onReorder: (oldIndex, newIndex) {
                          appProvider.reorderPlaylistLessons(
                            playlist.id,
                            oldIndex,
                            newIndex,
                          );
                        },
                        itemBuilder: (context, index) {
                          final lesson = lessons[index];
                          final series =
                              appProvider.getSeriesById(lesson.seriesId) ??
                              MockDataService.getSeriesById(lesson.seriesId);
                          final sheikh = series != null
                              ? (appProvider.getSheikhById(series.sheikhId) ??
                                    MockDataService.getSheikhById(
                                      series.sheikhId,
                                    ))
                              : null;

                          final isPlayingThisLesson =
                              audioProvider.currentLesson?.id == lesson.id &&
                              audioProvider.isPlaying;

                          return Container(
                            key: ValueKey(lesson.id),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isPlayingThisLesson
                                    ? AppColors.primaryDarkBrown
                                    : AppColors.dividerLight,
                                width: isPlayingThisLesson ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isPlayingThisLesson
                                      ? AppColors.primaryDarkBrown
                                      : AppColors.accentGoldBeige.withValues(
                                          alpha: 0.18,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: isPlayingThisLesson
                                      ? const Icon(
                                          Icons.equalizer_rounded,
                                          color: AppColors.textGoldLight,
                                          size: 20,
                                        )
                                      : Text(
                                          '${index + 1}',
                                          style: GoogleFonts.readexPro(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDarkBrown,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                lesson.title,
                                style: GoogleFonts.readexPro(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isPlayingThisLesson
                                      ? AppColors.primaryDarkBrown
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Row(
                                children: [
                                  if (sheikh != null) ...[
                                    Text(
                                      sheikh.name,
                                      style: GoogleFonts.readexPro(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: AppColors.dividerLight,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    lesson.duration,
                                    style: GoogleFonts.readexPro(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // زر التشغيل المباشر من هذا الدرس في القائمة
                                  IconButton(
                                    tooltip: 'تشغيل من هنا',
                                    icon: Icon(
                                      isPlayingThisLesson
                                          ? Icons.pause_circle_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: AppColors.primaryDarkBrown,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      if (isPlayingThisLesson) {
                                        audioProvider.pause();
                                      } else {
                                        audioProvider.startPlaylistPlayback(
                                          playlist: playlist,
                                          playlistLessons: lessons,
                                          startIndex: index,
                                        );
                                      }
                                    },
                                  ),
                                  // زر الحذف من القائمة
                                  IconButton(
                                    tooltip: 'إزالة من القائمة',
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      appProvider.removeLessonFromPlaylist(
                                        playlist.id,
                                        lesson.id,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                final currentSeries =
                                    series ??
                                    SeriesModel(
                                      id: lesson.seriesId,
                                      bookId: '',
                                      sheikhId: '',
                                      categoryId: '',
                                      title: playlist.title,
                                    );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LessonPlayerScreen(
                                      lesson: lesson,
                                      series: currentSeries,
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildDetailHeader(
    BuildContext context,
    CustomPlaylistModel playlist,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                  playlist.title,
                  style: GoogleFonts.readexPro(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
          if (playlist.description != null &&
              playlist.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                playlist.description!,
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: AppColors.textGoldLight.withValues(alpha: 0.85),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
