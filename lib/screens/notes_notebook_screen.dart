import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/audio_provider.dart';
import '../services/mock_data_service.dart';
import '../widgets/decorated_header.dart';
import 'lesson_player_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة كناشة الفوائد العلمية (NotesNotebookScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تعرض جميع الفوائد والفرائد التي دونها طالب العلم أثناء استماعه للدروس،
/// مع إمكانية البحث، النسخ المنسوب للمصدر، الحذف، والانتقال للدرس عند نفس اللحظة.
/// ═══════════════════════════════════════════════════════════════════════════
class NotesNotebookScreen extends StatefulWidget {
  const NotesNotebookScreen({super.key});

  @override
  State<NotesNotebookScreen> createState() => _NotesNotebookScreenState();
}

class _NotesNotebookScreenState extends State<NotesNotebookScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, AudioProvider>(
      builder: (context, appProvider, audioProvider, _) {
        final allNotes = appProvider.lessonNotes;
        final cleanQuery = _searchQuery.trim().toLowerCase();

        final filteredNotes = cleanQuery.isEmpty
            ? allNotes
            : allNotes.where((note) {
                return note.content.toLowerCase().contains(cleanQuery) ||
                    note.lessonTitle.toLowerCase().contains(cleanQuery) ||
                    note.bookTitle.toLowerCase().contains(cleanQuery) ||
                    note.sheikhName.toLowerCase().contains(cleanQuery);
              }).toList();

        return Scaffold(
          backgroundColor: AppColors.scaffoldCream,
          body: Column(
            children: [
              // ── 1. الهيدر العلوي المزخرف (RTL) ───────────────────────────
              DecoratedHeader(
                title: 'كناشة الفوائد',
                showSearchIcon: false,
                onBackPressed: () => Navigator.pop(context),
              ),

              // ── 2. شريط البحث وإحصائية الفوائد ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  children: [
                    // حقل البحث في الفوائد
                    TextField(
                      controller: _searchController,
                      style: GoogleFonts.readexPro(fontSize: 13.5),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث في نصوص الفوائد، الكتب، أو الشيوخ...',
                        hintStyle: GoogleFonts.readexPro(
                          fontSize: 12.5,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.cardWhite,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.iconGold,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.dividerLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.dividerLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primaryDarkBrown,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // إحصائية عدد الفوائد المسجلة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.edit_note_rounded,
                              size: 18,
                              color: AppColors.primaryDarkBrown,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'مجموع الفوائد المدوّنة: ${filteredNotes.length}',
                              style: GoogleFonts.readexPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDarkBrown,
                              ),
                            ),
                          ],
                        ),
                        if (_searchQuery.isNotEmpty)
                          Text(
                            'نتائج التصفية',
                            style: GoogleFonts.readexPro(
                              fontSize: 11.5,
                              color: AppColors.iconGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 3. قائمة بطاقات الفوائد ─────────────────────────────────
              Expanded(
                child: filteredNotes.isEmpty
                    ? _buildEmptyState(allNotes.isEmpty)
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 26),
                        itemCount: filteredNotes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          // عرض الأحدث أولاً
                          final note =
                              filteredNotes[filteredNotes.length - 1 - index];
                          return _buildNoteCard(
                            context,
                            note,
                            appProvider,
                            audioProvider,
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

  /// بطاقة الفائدة المستقلة
  Widget _buildNoteCard(
    BuildContext context,
    LessonNoteModel note,
    AppProvider appProvider,
    AudioProvider audioProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerLight),
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
          // ── شريط رأس الفائدة: مصدر المتن والشارح والتوقيت ──────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر شارة التوقيت الزمني (ينتقل للدرس والصوت عند النقر)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _goToLesson(context, note, appProvider, audioProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkBrown,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 15,
                        color: AppColors.textGoldLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        note.formattedTimestamp,
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textGoldLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // اسم الكتاب والشيخ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.lessonTitle,
                      style: GoogleFonts.readexPro(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkBrown,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${note.bookTitle} • ${note.sheikhName}',
                      style: GoogleFonts.readexPro(
                        fontSize: 11.5,
                        color: AppColors.iconGold,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.dividerLight, height: 1),
          const SizedBox(height: 12),

          // ── نص الفائدة العلمي ──────────────────────────────────────
          Text(
            note.content,
            style: GoogleFonts.readexPro(
              fontSize: 13.5,
              height: 1.65,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.justify,
          ),

          const SizedBox(height: 14),

          // ── شريط أدوات الفائدة (تاريخ، نسخ، حذف، انتقال) ───────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // التاريخ
              Text(
                '${note.createdAt.year}/${note.createdAt.month.toString().padLeft(2, '0')}/${note.createdAt.day.toString().padLeft(2, '0')}',
                style: GoogleFonts.readexPro(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر نسخ الفائدة مع المصدر
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'نسخ مع المصدر',
                    color: AppColors.iconGold,
                    onPressed: () {
                      final copyText =
                          '"${note.content}"\n\n— من درس: ${note.lessonTitle} (عند ${note.formattedTimestamp})\n— شرح: ${note.bookTitle}\n— للشيخ: ${note.sheikhName}\n(تطبيق تسهيل للعلوم الشرعية)';
                      Clipboard.setData(ClipboardData(text: copyText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم نسخ الفائدة مع مصدرها إلى الحافظة بنجاح',
                            style: GoogleFonts.readexPro(),
                          ),
                          backgroundColor: AppColors.primaryDarkBrown,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  // زر الانتقال المباشر للدرس
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    tooltip: 'فتح الدرس عند هذه اللحظة',
                    color: AppColors.primaryDarkBrown,
                    onPressed: () => _goToLesson(
                      context,
                      note,
                      appProvider,
                      audioProvider,
                    ),
                  ),

                  // زر حذف الفائدة
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    tooltip: 'حذف',
                    color: const Color(0xFFC62828),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: AppColors.cardWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'حذف الفائدة',
                            style: GoogleFonts.readexPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDarkBrown,
                            ),
                          ),
                          content: Text(
                            'هل أنت متأكد من رغبتك في حذف هذه الفائدة من الكناشة؟',
                            style: GoogleFonts.readexPro(fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text(
                                'إلغاء',
                                style: GoogleFonts.readexPro(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC62828),
                              ),
                              onPressed: () => Navigator.pop(c, true),
                              child: Text(
                                'حذف',
                                style: GoogleFonts.readexPro(),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await appProvider.deleteLessonNote(note.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// فتح مشغل الدرس والانتقال للتوقيت المحدد للفائدة
  void _goToLesson(
    BuildContext context,
    LessonNoteModel note,
    AppProvider appProvider,
    AudioProvider audioProvider,
  ) {
    final lesson = appProvider.getLessonById(note.lessonId) ??
        MockDataService.lessons
            .where((l) => l.id == note.lessonId)
            .firstOrNull;
    if (lesson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر العثور على الدرس المرتبط بهذه الفائدة.',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: AppColors.primaryDarkBrown,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final series = appProvider.getSeriesById(lesson.seriesId) ??
        MockDataService.series
            .where((s) => s.id == lesson.seriesId)
            .firstOrNull ??
        SeriesModel(
          id: lesson.seriesId,
          title: note.bookTitle,
          bookId: '',
          sheikhId: '',
          categoryId: '',
          lessonsCount: 1,
        );

    // تقديم الصوت إلى اللحظة الزمنية للفائدة
    audioProvider.loadAndPlayLesson(
      lesson: lesson,
      series: series,
      autoPlay: true,
    );
    audioProvider.seek(Duration(seconds: note.timestampSeconds));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPlayerScreen(
          lesson: lesson,
          series: series,
        ),
      ),
    );
  }

  /// الحالة الفارغة عند عدم وجود فوائد
  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 38,
                color: AppColors.iconGold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCompletelyEmpty
                  ? 'كناشة الفوائد فارغة'
                  : 'لم يتم العثور على فوائد مطابقة لبحثك',
              style: GoogleFonts.readexPro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDarkBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompletelyEmpty
                  ? 'أثناء استماعك لأي درس علمي، اضغط على زر "تدوين فائدة" لتوثيق دررك وفرائدك مع التوقيت الدقيق.'
                  : 'جرّب البحث بكلمة أخرى أو تفقد قائمة جميع الفوائد.',
              style: GoogleFonts.readexPro(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
