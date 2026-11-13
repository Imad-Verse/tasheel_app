import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mock_data_service.dart';
import '../screens/category_books_screen.dart';
import '../screens/book_details_screen.dart';
import '../screens/sheikh_details_screen.dart';
import '../screens/series_lessons_screen.dart';
import '../screens/lesson_player_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// واجهة البحث الشامل لتطبيق تسهيل (GlobalSearchDelegate)
/// ═══════════════════════════════════════════════════════════════════════════
/// تتيح البحث الفوري والمقسم في:
/// 1. الأقسام العلمية (العقيدة، الفقه...)
/// 2. المتون والكتب (كتاب التوحيد، الأصول الثلاثة...)
/// 3. الشيوخ والعلماء (ابن عثيمين، ابن باز...)
/// 4. الشروحات والدروس العلمية
/// ═══════════════════════════════════════════════════════════════════════════
class GlobalSearchDelegate extends SearchDelegate<String?> {
  GlobalSearchDelegate()
      : super(
          searchFieldLabel: 'ابحث عن متن، شيخ، أو علم شرعي...',
          searchFieldStyle: GoogleFonts.readexPro(
            color: AppColors.textWhite,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          keyboardType: TextInputType.text,
        );

  /// فتح شاشة البحث بسهولة
  static Future<String?> show(BuildContext context) {
    return showSearch<String?>(
      context: context,
      delegate: GlobalSearchDelegate(),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDarkBrown,
        foregroundColor: AppColors.textGoldLight,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textGoldLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.readexPro(
          color: AppColors.textGoldLight.withValues(alpha: 0.6),
          fontSize: 15,
        ),
        border: InputBorder.none,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldCream,
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'مسح',
          icon: const Icon(Icons.clear_rounded, color: AppColors.textGoldLight),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'رجوع',
      icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.textGoldLight),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return _buildQuickSuggestions(context);
    }
    return _buildSearchResults(context);
  }

  /// مقترحات سريعة عند فتح البحث قبل الكتابة
  Widget _buildQuickSuggestions(BuildContext context) {
    AppProvider? appProvider;
    try {
      appProvider = Provider.of<AppProvider>(context, listen: false);
    } catch (_) {}
    final categories = appProvider?.categories ?? MockDataService.categories;

    final popularTags = [
      'كتاب التوحيد',
      'ابن عثيمين',
      'العقيدة',
      'زاد المستقنع',
      'الفوزان',
      'الفقه',
      'الأصول الثلاثة',
      'عبد الرزاق البدر',
    ];

    return Container(
      color: AppColors.scaffoldCream,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AppColors.iconGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'عمليات البحث الشائعة',
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: popularTags.map((tag) {
              return InkWell(
                onTap: () {
                  query = tag;
                  showResults(context);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.dividerLight),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // تصفح سريع للأقسام
          Row(
            children: [
              const Icon(Icons.category_rounded, color: AppColors.iconGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'تصفح الأقسام العلمية',
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Material(
                  color: AppColors.cardWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(Icons.star_rounded, color: AppColors.iconGold),
                    title: Text(
                      cat.name,
                      style: GoogleFonts.readexPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${cat.booksCount} كتب • ${cat.lessonsCount} درس',
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.iconGold,
                      size: 20,
                    ),
                    onTap: () {
                      close(context, cat.name);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryBooksScreen(category: cat),
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
  }

  /// نتائج البحث مقسمة ومفصلة
  Widget _buildSearchResults(BuildContext context) {
    final cleanQuery = query.trim().toLowerCase();

    AppProvider? appProvider;
    try {
      appProvider = Provider.of<AppProvider>(context, listen: false);
    } catch (_) {}

    final allCategories = appProvider?.categories ?? MockDataService.categories;
    final allBooks = appProvider?.books ?? MockDataService.books;
    final allSheikhs = appProvider?.sheikhs ?? MockDataService.sheikhs;
    final allSeries = appProvider?.series ?? MockDataService.series;
    final allLessons = appProvider?.lessons ?? MockDataService.lessons;

    // فلترة الأقسام
    final matchingCategories = allCategories
        .where((c) => c.name.toLowerCase().contains(cleanQuery))
        .toList();

    // فلترة الكتب
    final matchingBooks = allBooks
        .where((b) =>
            b.title.toLowerCase().contains(cleanQuery) ||
            b.author.toLowerCase().contains(cleanQuery) ||
            b.description.toLowerCase().contains(cleanQuery))
        .toList();

    // فلترة الشيوخ
    final matchingSheikhs = allSheikhs
        .where((s) =>
            s.name.toLowerCase().contains(cleanQuery) ||
            s.shortBio.toLowerCase().contains(cleanQuery))
        .toList();

    // فلترة الشروحات والدروس
    final matchingSeries = allSeries
        .where((s) => s.title.toLowerCase().contains(cleanQuery))
        .toList();

    // فلترة نصوص التفريغات للدروس (Full-text transcript search)
    final matchingTranscriptLessons = <Map<String, dynamic>>[];
    if (cleanQuery.isNotEmpty) {
      for (final l in allLessons) {
        if (l.hasTranscript && l.transcript.toLowerCase().contains(cleanQuery)) {
          final transcript = l.transcript;
          final lowerTranscript = transcript.toLowerCase();
          final index = lowerTranscript.indexOf(cleanQuery);
          final start = (index - 35).clamp(0, transcript.length);
          final end = (index + cleanQuery.length + 55).clamp(0, transcript.length);
          final prefix = start > 0 ? '...' : '';
          final suffix = end < transcript.length ? '...' : '';
          final snippet = prefix +
              transcript.substring(start, end).replaceAll('\n', ' ') +
              suffix;

          matchingTranscriptLessons.add({
            'lesson': l,
            'snippet': snippet,
          });
        }
      }
    }

    final totalCount = matchingCategories.length +
        matchingBooks.length +
        matchingSheikhs.length +
        matchingSeries.length +
        matchingTranscriptLessons.length;

    if (totalCount == 0) {
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
                  Icons.search_off_rounded,
                  color: AppColors.iconGold,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'لم نجد نتائج مطابقة لـ "$query"',
                style: GoogleFonts.readexPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'جرب البحث بكلمة أخرى مثل: العقيدة، الفقه، ابن عثيمين، كتاب التوحيد',
                style: GoogleFonts.readexPro(
                  fontSize: 13,
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

    return Container(
      color: AppColors.scaffoldCream,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ── نتائج الأقسام العلمية ─────────────────────────────────
          if (matchingCategories.isNotEmpty) ...[
            _buildSectionHeader('الأقسام العلمية', matchingCategories.length),
            ...matchingCategories.map((c) => _buildCategoryResultTile(context, c)),
            const SizedBox(height: 16),
          ],

          // ── نتائج الكتب والمتون ──────────────────────────────────
          if (matchingBooks.isNotEmpty) ...[
            _buildSectionHeader('المتون والكتب', matchingBooks.length),
            ...matchingBooks.map((b) => _buildBookResultTile(context, b)),
            const SizedBox(height: 16),
          ],

          // ── نتائج الشيوخ والعلماء ────────────────────────────────
          if (matchingSheikhs.isNotEmpty) ...[
            _buildSectionHeader('الشيوخ والعلماء', matchingSheikhs.length),
            ...matchingSheikhs.map((s) => _buildSheikhResultTile(context, s)),
            const SizedBox(height: 16),
          ],

          // ── نتائج الشروحات والسلاسل ──────────────────────────────
          if (matchingSeries.isNotEmpty) ...[
            _buildSectionHeader('الشروحات العلمية', matchingSeries.length),
            ...matchingSeries.map((s) => _buildSeriesResultTile(context, s)),
            const SizedBox(height: 16),
          ],

          // ── نتائج البحث في نصوص التفريغات ────────────────────────
          if (matchingTranscriptLessons.isNotEmpty) ...[
            _buildSectionHeader(
              'في نصوص التفريغات للدروس',
              matchingTranscriptLessons.length,
            ),
            ...matchingTranscriptLessons.map(
              (item) => _buildTranscriptResultTile(
                context,
                item['lesson'] as LessonModel,
                item['snippet'] as String,
                cleanQuery,
                appProvider,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.readexPro(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDarkBrown,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentGoldBeige.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.readexPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryResultTile(BuildContext context, CategoryModel cat) {
    return Card(
      color: AppColors.cardWhite,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.star_rounded, color: AppColors.iconGold, size: 22),
        ),
        title: Text(
          cat.name,
          style: GoogleFonts.readexPro(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${cat.booksCount} كتب • ${cat.sheikhsCount} شيوخ • ${cat.lessonsCount} درس',
          style: GoogleFonts.readexPro(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.iconGold),
        onTap: () {
          close(context, cat.name);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryBooksScreen(category: cat),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookResultTile(BuildContext context, BookModel book) {
    return Card(
      color: AppColors.cardWhite,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.menu_book_rounded, color: AppColors.iconGold, size: 22),
        ),
        title: Text(
          book.title,
          style: GoogleFonts.readexPro(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'المؤلف: ${book.author} • ${book.seriesCount} شروحات',
          style: GoogleFonts.readexPro(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.iconGold),
        onTap: () {
          close(context, book.title);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailsScreen(book: book),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheikhResultTile(BuildContext context, SheikhModel sheikh) {
    return Card(
      color: AppColors.cardWhite,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_rounded, color: AppColors.iconGold, size: 22),
        ),
        title: Text(
          sheikh.name,
          style: GoogleFonts.readexPro(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${sheikh.booksCount} شروحات • ${sheikh.lessonsCount} درس',
          style: GoogleFonts.readexPro(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.iconGold),
        onTap: () {
          close(context, sheikh.name);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SheikhDetailsScreen(sheikh: sheikh),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeriesResultTile(BuildContext context, SeriesModel series) {
    final sheikh = MockDataService.getSheikhById(series.sheikhId);

    return Card(
      color: AppColors.cardWhite,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.audiotrack_rounded, color: AppColors.iconGold, size: 22),
        ),
        title: Text(
          series.title,
          style: GoogleFonts.readexPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'الشارح: ${sheikh?.name ?? ''} • ${series.lessonsCount} درس',
          style: GoogleFonts.readexPro(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.iconGold),
        onTap: () {
          close(context, series.title);
          final book = MockDataService.getBookById(series.bookId);
          final sheikh = MockDataService.getSheikhById(series.sheikhId);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SeriesLessonsScreen(
                series: series,
                book: book,
                sheikh: sheikh,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptResultTile(
    BuildContext context,
    LessonModel lesson,
    String snippet,
    String highlightQuery,
    AppProvider? appProvider,
  ) {
    final series = appProvider?.getSeriesById(lesson.seriesId) ??
        MockDataService.series
            .where((s) => s.id == lesson.seriesId)
            .firstOrNull;
    final book = appProvider?.getBookById(series?.bookId ?? '') ??
        MockDataService.getBookById(series?.bookId ?? '');
    final sheikh = appProvider?.getSheikhById(series?.sheikhId ?? '') ??
        MockDataService.getSheikhById(series?.sheikhId ?? '');

    return Card(
      color: AppColors.cardWhite,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.dividerLight),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          close(context, highlightQuery);
          final actualSeries = series ??
              SeriesModel(
                id: lesson.seriesId,
                title: lesson.title,
                bookId: '',
                sheikhId: '',
                categoryId: '',
                lessonsCount: 1,
              );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonPlayerScreen(
                lesson: lesson,
                series: actualSeries,
                initialSearchQuery: highlightQuery,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBeige.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.iconGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: GoogleFonts.readexPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${book?.title ?? ""} • ${sheikh?.name ?? ""}',
                      style: GoogleFonts.readexPro(
                        fontSize: 11.5,
                        color: AppColors.iconGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildHighlightedSnippet(snippet, highlightQuery),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.iconGold,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedSnippet(String snippet, String q) {
    if (q.isEmpty) {
      return Text(
        snippet,
        style: GoogleFonts.amiri(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      );
    }

    final lowerSnippet = snippet.toLowerCase();
    final lowerQuery = q.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerSnippet.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: snippet.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: snippet.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: snippet.substring(index, index + q.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFE082),
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723),
          ),
        ),
      );
      start = index + q.length;
    }

    return Text.rich(
      TextSpan(
        style: GoogleFonts.amiri(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
