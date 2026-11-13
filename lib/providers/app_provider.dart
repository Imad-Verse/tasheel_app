import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// مزود الحالة الشامل للتطبيق ولوحة التحكم السحابية (AppProvider)
/// ═══════════════════════════════════════════════════════════════════════════
/// يدير:
/// - حالة الاتصال بـ Firebase أو الحفظ المحلي المستمر في SharedPreferences.
/// - البيانات الحية: الأقسام، الشيوخ، الكتب، الشروحات، والدروس.
/// - عمليات الإدارة الكاملة (CRUD) والإضافة الجماعية Bulk Add للدروس.
/// - التحديث التلقائي للعدادات والإحصائيات عبر recalculateAllCounts().
/// - تتبع آخر درس مستمع والمحفوظات وإعدادات التطبيق.
/// ═══════════════════════════════════════════════════════════════════════════
class AppProvider extends ChangeNotifier {
  final bool isFirebaseConnected;

  AppProvider({this.isFirebaseConnected = false}) {
    _initData();
  }

  // مفاتيح SharedPreferences
  static const String _keyStudiedSeries = 'studied_series_ids';
  static const String _keyCompletedLessons = 'completed_lesson_ids';
  static const String _keyUserName = 'tasheel_user_name';
  static const String _keyFontSize = 'tasheel_font_size';
  static const String _keyAutoPlay = 'tasheel_autoplay_next';

  // مفاتيح حفظ المحتوى الإداري محلياً
  static const String _keyAdminCategories = 'tasheel_admin_categories';
  static const String _keyAdminSheikhs = 'tasheel_admin_sheikhs';
  static const String _keyAdminBooks = 'tasheel_admin_books';
  static const String _keyAdminSeries = 'tasheel_admin_series';
  static const String _keyAdminLessons = 'tasheel_admin_lessons';

  // ─── 0. الملف الشخصي وإعدادات التطبيق ──────────────────────────────────────
  String _userName = 'أبو الحارث عماد بعلول';
  String get userName => _userName;

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && trimmed != _userName) {
      _userName = trimmed;
      notifyListeners();
      await _savePreferences();
    }
  }

  double _defaultTranscriptFontSize = 17.0;
  double get defaultTranscriptFontSize => _defaultTranscriptFontSize;

  Future<void> setDefaultTranscriptFontSize(double size) async {
    _defaultTranscriptFontSize = size;
    notifyListeners();
    await _savePreferences();
  }

  bool _autoPlayNextLesson = true;
  bool get autoPlayNextLesson => _autoPlayNextLesson;

  Future<void> setAutoPlayNextLesson(bool value) async {
    _autoPlayNextLesson = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> clearCache() async {
    notifyListeners();
  }

  // ─── 1. التنقل بين التبويبات ─────────────────────────────────────────────
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setCurrentTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  static const List<String> tabLabels = [
    'الرئيسية',
    'المتون',
    'الشيوخ',
    'المحفوظات',
    'المزيد',
  ];

  static const List<IconData> tabIcons = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.person_rounded,
    Icons.bookmark_rounded,
    Icons.menu_rounded,
  ];

  // ─── 2. خيارات العرض (قائمة / شبكة) ──────────────────────────────────────
  bool _isCategoriesGridView = false;
  bool get isCategoriesGridView => _isCategoriesGridView;

  void toggleCategoriesView() {
    _isCategoriesGridView = !_isCategoriesGridView;
    notifyListeners();
  }

  void setCategoriesGridView(bool value) {
    if (_isCategoriesGridView != value) {
      _isCategoriesGridView = value;
      notifyListeners();
    }
  }

  bool _isSheikhsGridView = false;
  bool get isSheikhsGridView => _isSheikhsGridView;

  void toggleSheikhsView() {
    _isSheikhsGridView = !_isSheikhsGridView;
    notifyListeners();
  }

  void setSheikhsGridView(bool value) {
    if (_isSheikhsGridView != value) {
      _isSheikhsGridView = value;
      notifyListeners();
    }
  }

  // ─── 3. بيانات المحتوى الحية (Mutable Content Lists) ─────────────────────
  final List<CategoryModel> _categories = [];
  final List<SheikhModel> _sheikhs = [];
  final List<BookModel> _books = [];
  final List<SeriesModel> _series = [];
  final List<LessonModel> _lessons = [];

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<SheikhModel> get sheikhs => List.unmodifiable(_sheikhs);
  List<BookModel> get books => List.unmodifiable(_books);
  List<SeriesModel> get series => List.unmodifiable(_series);
  List<LessonModel> get lessons => List.unmodifiable(_lessons);

  // ─── 4. آخر درس تم الاستماع إليه ────────────────────────────────────────
  LessonModel? _lastPlayedLesson;
  LessonModel? get lastPlayedLesson => _lastPlayedLesson;

  SeriesModel? _lastPlayedSeries;
  SeriesModel? get lastPlayedSeries => _lastPlayedSeries;

  BookModel? _lastPlayedBook;
  BookModel? get lastPlayedBook => _lastPlayedBook;

  SheikhModel? _lastPlayedSheikh;
  SheikhModel? get lastPlayedSheikh => _lastPlayedSheikh;

  void setLastPlayedLesson(LessonModel lesson) {
    _lastPlayedLesson = lesson;
    _lastPlayedSeries = _series.firstWhere(
      (s) => s.id == lesson.seriesId,
      orElse: () => _series.isNotEmpty
          ? _series.first
          : const SeriesModel(
              id: '', bookId: '', sheikhId: '', categoryId: '', title: ''),
    );
    _lastPlayedBook = getBookById(_lastPlayedSeries?.bookId ?? '');
    _lastPlayedSheikh = getSheikhById(_lastPlayedSeries?.sheikhId ?? '');
    notifyListeners();
  }

  // ─── 5. نظام المحفوظات (المتون قيد الدراسة) ──────────────────────────────
  final List<String> _studiedSeriesIds = [
    'series_tawheed_uthaymeen',
    'series_usool_uthaymeen',
  ];
  List<String> get studiedSeriesIds => List.unmodifiable(_studiedSeriesIds);
  int get studiedSeriesCount => _studiedSeriesIds.length;

  bool isSeriesStudied(String seriesId) => _studiedSeriesIds.contains(seriesId);

  Future<void> toggleStudySeries(String seriesId) async {
    if (_studiedSeriesIds.contains(seriesId)) {
      _studiedSeriesIds.remove(seriesId);
    } else {
      _studiedSeriesIds.add(seriesId);
    }
    notifyListeners();
    await _savePreferences();
  }

  List<SeriesModel> getStudiedSeries() {
    return _series.where((s) => _studiedSeriesIds.contains(s.id)).toList();
  }

  // ─── 6. تتبع الدروس المكتملة وإحصائيات الإنجاز ─────────────────────────
  final List<String> _completedLessonIds = [
    'lesson_tawheed_uth_01',
    'lesson_usool_uth_01',
  ];
  List<String> get completedLessonIds => List.unmodifiable(_completedLessonIds);

  bool isLessonCompleted(String lessonId) => _completedLessonIds.contains(lessonId);

  Future<void> toggleLessonCompleted(String lessonId) async {
    if (_completedLessonIds.contains(lessonId)) {
      _completedLessonIds.remove(lessonId);
    } else {
      _completedLessonIds.add(lessonId);
    }
    notifyListeners();
    await _savePreferences();
  }

  double getSeriesProgress(String seriesId) {
    final seriesLessons = getLessonsBySeries(seriesId);
    if (seriesLessons.isEmpty) return 0.0;
    final completed = seriesLessons.where((l) => _completedLessonIds.contains(l.id)).length;
    return completed / seriesLessons.length;
  }

  int getCompletedLessonsInSeries(String seriesId) {
    final seriesLessons = getLessonsBySeries(seriesId);
    return seriesLessons.where((l) => _completedLessonIds.contains(l.id)).length;
  }

  int get completedLessonsCount => _completedLessonIds.length;
  int get completedSeriesCount => _studiedSeriesIds.where((id) => getSeriesProgress(id) >= 1.0).length;
  int get listeningHours => ((_completedLessonIds.length * 45) / 60).round();

  // ─── 7. مقولات السلف الصالح ──────────────────────────────────────────────
  final List<Map<String, String>> _quotes = MockDataService.dailyQuotes;
  List<Map<String, String>> get quotes => List.unmodifiable(_quotes);

  int _currentQuoteIndex = 0;
  int get currentQuoteIndex => _currentQuoteIndex;

  Map<String, String> get currentQuote => _quotes[_currentQuoteIndex % _quotes.length];

  void nextQuote() {
    _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
    notifyListeners();
  }

  // ─── 8. الدوال الاستعلامية الحية ──────────────────────────────────────────
  List<BookModel> getBooksByCategory(String categoryId) {
    return _books.where((b) => b.categoryId == categoryId).toList();
  }

  List<SeriesModel> getSeriesByBook(String bookId) {
    return _series.where((s) => s.bookId == bookId).toList();
  }

  List<SeriesModel> getSeriesBySheikh(String sheikhId, {String? categoryId}) {
    var list = _series.where((s) => s.sheikhId == sheikhId).toList();
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      list = list.where((s) => s.categoryId == categoryId).toList();
    }
    return list;
  }

  List<CategoryModel> getCategoriesForSheikh(String sheikhId) {
    final sheikhSeries = _series.where((s) => s.sheikhId == sheikhId);
    final categoryIds = sheikhSeries.map((s) => s.categoryId).toSet();
    return _categories.where((c) => categoryIds.contains(c.id)).toList();
  }

  List<LessonModel> getLessonsBySeries(String seriesId) {
    final list = _lessons.where((l) => l.seriesId == seriesId).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  SheikhModel? getSheikhById(String id) {
    try {
      return _sheikhs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  BookModel? getBookById(String id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  SeriesModel? getSeriesById(String id) {
    try {
      return _series.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  LessonModel? getLessonById(String id) {
    try {
      return _lessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 9. التحديث التلقائي للعدادات (Auto-Counters Recalculation) ─────────────
  // ═══════════════════════════════════════════════════════════════════════════
  /// يُعاد حسابه تلقائياً بعد كل عملية إضافة أو تعديل أو حذف في لوحة التحكم:
  /// - عدد الدروس داخل كل شرح
  /// - عدد الشروحات داخل كل كتاب
  /// - عدد الكتب والدروس التابعة لكل شيخ
  /// - عدد الكتب والشيوخ والدروس في كل قسم علمي
  void recalculateAllCounts() {
    // 1. تحديث عدد الدروس في كل شرح
    for (int i = 0; i < _series.length; i++) {
      final s = _series[i];
      final count = _lessons.where((l) => l.seriesId == s.id).length;
      _series[i] = s.copyWith(lessonsCount: count);
    }

    // 2. تحديث عدد الشروحات في كل كتاب
    for (int i = 0; i < _books.length; i++) {
      final b = _books[i];
      final count = _series.where((s) => s.bookId == b.id).length;
      _books[i] = b.copyWith(seriesCount: count);
    }

    // 3. تحديث عدد الكتب والدروس التابعة لكل شيخ
    for (int i = 0; i < _sheikhs.length; i++) {
      final sh = _sheikhs[i];
      final sheikhSeries = _series.where((s) => s.sheikhId == sh.id).toList();
      final uniqueBookIds = sheikhSeries.map((s) => s.bookId).toSet();
      final totalLessons = sheikhSeries.fold<int>(
        0,
        (total, s) => total + s.lessonsCount,
      );
      _sheikhs[i] = sh.copyWith(
        booksCount: uniqueBookIds.length,
        lessonsCount: totalLessons,
      );
    }

    // 4. تحديث عدد الكتب والشيوخ والدروس في كل قسم
    for (int i = 0; i < _categories.length; i++) {
      final cat = _categories[i];
      final catBooks = _books.where((b) => b.categoryId == cat.id).toList();
      final catSeries = _series.where((s) => s.categoryId == cat.id).toList();
      final uniqueSheikhIds = catSeries.map((s) => s.sheikhId).toSet();
      final totalLessons = catSeries.fold<int>(
        0,
        (total, s) => total + s.lessonsCount,
      );
      _categories[i] = cat.copyWith(
        booksCount: catBooks.length,
        sheikhsCount: uniqueSheikhIds.length,
        lessonsCount: totalLessons,
      );
    }

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 10. عمليات إدارة لوحة التحكم (Admin CRUD Operations) ───────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  // ── الأقسام ───────────────────────────────────────────────────────────────
  Future<void> addCategory(CategoryModel category) async {
    _categories.add(category);
    recalculateAllCounts();
    await _saveDataToPersistence();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(category.id)
            .set(category.toMap());
      } catch (e) {
        debugPrint('Firestore category add error: $e');
      }
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      _categories[idx] = category;
      recalculateAllCounts();
      await _saveDataToPersistence();
      if (isFirebaseConnected) {
        try {
          await FirebaseFirestore.instance
              .collection('categories')
              .doc(category.id)
              .update(category.toMap());
        } catch (e) {
          debugPrint('Firestore category update error: $e');
        }
      }
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.id == categoryId);
    recalculateAllCounts();
    await _saveDataToPersistence();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryId)
            .delete();
      } catch (e) {
        debugPrint('Firestore category delete error: $e');
      }
    }
  }

  // ── الشيوخ ────────────────────────────────────────────────────────────────
  Future<void> addSheikh(SheikhModel sheikh) async {
    _sheikhs.add(sheikh);
    recalculateAllCounts();
    await _saveDataToPersistence();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('sheikhs')
            .doc(sheikh.id)
            .set(sheikh.toMap());
      } catch (e) {
        debugPrint('Firestore sheikh add error: $e');
      }
    }
  }

  Future<void> updateSheikh(SheikhModel sheikh) async {
    final idx = _sheikhs.indexWhere((s) => s.id == sheikh.id);
    if (idx != -1) {
      _sheikhs[idx] = sheikh;
      recalculateAllCounts();
      await _saveDataToPersistence();
      if (isFirebaseConnected) {
        try {
          await FirebaseFirestore.instance
              .collection('sheikhs')
              .doc(sheikh.id)
              .update(sheikh.toMap());
        } catch (e) {
          debugPrint('Firestore sheikh update error: $e');
        }
      }
    }
  }

  Future<void> deleteSheikh(String sheikhId) async {
    _sheikhs.removeWhere((s) => s.id == sheikhId);
    recalculateAllCounts();
    await _saveDataToPersistence();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('sheikhs')
            .doc(sheikhId)
            .delete();
      } catch (e) {
        debugPrint('Firestore sheikh delete error: $e');
      }
    }
  }

  // ── الكتب ─────────────────────────────────────────────────────────────────
  Future<void> addBook(BookModel book) async {
    _books.add(book);
    recalculateAllCounts();
    await _saveDataToPersistence();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('books')
            .doc(book.id)
            .set(book.toMap());
      } catch (e) {
        debugPrint('Firestore book add error: $e');
      }
    }
  }

  Future<void> updateBook(BookModel book) async {
    final idx = _books.indexWhere((b) => b.id == book.id);
    if (idx != -1) {
      _books[idx] = book;
      recalculateAllCounts();
      await _saveDataToPersistence();
      if (isFirebaseConnected) {
        try {
          await FirebaseFirestore.instance
              .collection('books')
              .doc(book.id)
              .update(book.toMap());
        } catch (e) {
          debugPrint('Firestore book update error: $e');
        }
      }
    }
  }

  Future<void> deleteBook(String bookId) async {
    _books.removeWhere((b) => b.id == bookId);
    recalculateAllCounts();
    await _saveDataToPersistence();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('books')
            .doc(bookId)
            .delete();
      } catch (e) {
        debugPrint('Firestore book delete error: $e');
      }
    }
  }

  // ── الشروحات ──────────────────────────────────────────────────────────────
  Future<void> addSeries(SeriesModel seriesItem) async {
    _series.add(seriesItem);
    recalculateAllCounts();
    await _saveDataToPersistence();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('series')
            .doc(seriesItem.id)
            .set(seriesItem.toMap());
      } catch (e) {
        debugPrint('Firestore series add error: $e');
      }
    }
  }

  Future<void> updateSeries(SeriesModel seriesItem) async {
    final idx = _series.indexWhere((s) => s.id == seriesItem.id);
    if (idx != -1) {
      _series[idx] = seriesItem;
      recalculateAllCounts();
      await _saveDataToPersistence();
      if (isFirebaseConnected) {
        try {
          await FirebaseFirestore.instance
              .collection('series')
              .doc(seriesItem.id)
              .update(seriesItem.toMap());
        } catch (e) {
          debugPrint('Firestore series update error: $e');
        }
      }
    }
  }

  Future<void> deleteSeries(String seriesId) async {
    _series.removeWhere((s) => s.id == seriesId);
    recalculateAllCounts();
    await _saveDataToPersistence();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('series')
            .doc(seriesId)
            .delete();
      } catch (e) {
        debugPrint('Firestore series delete error: $e');
      }
    }
  }

  // ── الدروس (فردية + جماعية Bulk Add) ──────────────────────────────────────
  Future<void> addLesson(LessonModel lesson) async {
    _lessons.add(lesson);
    recalculateAllCounts();
    await _saveDataToPersistence();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('lessons')
            .doc(lesson.id)
            .set(lesson.toMap());
      } catch (e) {
        debugPrint('Firestore lesson add error: $e');
      }
    }
  }

  Future<void> updateLesson(LessonModel lesson) async {
    final idx = _lessons.indexWhere((l) => l.id == lesson.id);
    if (idx != -1) {
      _lessons[idx] = lesson;
      recalculateAllCounts();
      await _saveDataToPersistence();
      if (isFirebaseConnected) {
        try {
          await FirebaseFirestore.instance
              .collection('lessons')
              .doc(lesson.id)
              .update(lesson.toMap());
        } catch (e) {
          debugPrint('Firestore lesson update error: $e');
        }
      }
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    _lessons.removeWhere((l) => l.id == lessonId);
    recalculateAllCounts();
    await _saveDataToPersistence();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('lessons')
            .doc(lessonId)
            .delete();
      } catch (e) {
        debugPrint('Firestore lesson delete error: $e');
      }
    }
  }

  /// الإضافة الجماعية السريعة للروابط (Bulk Add)
  Future<int> bulkAddLessons({
    required String seriesId,
    required String titlePrefix,
    required List<String> rawEntries,
  }) async {
    int addedCount = 0;
    final existingLessons = getLessonsBySeries(seriesId);
    int currentOrder = existingLessons.isEmpty
        ? 1
        : existingLessons.map((l) => l.order).reduce((a, b) => a > b ? a : b) + 1;

    for (final raw in rawEntries) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      String title;
      String audioUrl;

      if (line.contains('|')) {
        final parts = line.split('|');
        title = parts[0].trim();
        audioUrl = parts.sublist(1).join('|').trim();
      } else {
        title = '$titlePrefix $currentOrder';
        audioUrl = line;
      }

      final newLesson = LessonModel(
        id: 'lesson_${seriesId}_${DateTime.now().millisecondsSinceEpoch}_$addedCount',
        seriesId: seriesId,
        title: title,
        order: currentOrder,
        duration: '40:00',
        audioUrl: audioUrl,
      );

      _lessons.add(newLesson);
      currentOrder++;
      addedCount++;
    }

    if (addedCount > 0) {
      recalculateAllCounts();
      await _saveDataToPersistence();
    }

    return addedCount;
  }

  /// تحديث التفريغ النصي لدرس معين
  Future<void> updateLessonTranscript(String lessonId, String newTranscript) async {
    final idx = _lessons.indexWhere((l) => l.id == lessonId);
    if (idx != -1) {
      _lessons[idx] = _lessons[idx].copyWith(transcript: newTranscript.trim());
      await _saveDataToPersistence();
      notifyListeners();
      if (isFirebaseConnected) {
        try {
          await FirebaseFirestore.instance
              .collection('lessons')
              .doc(lessonId)
              .update({'transcript': newTranscript.trim()});
        } catch (e) {
          debugPrint('Firestore transcript update error: $e');
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 11. رفع البيانات الأولية إلى السحابة (Seed Data to Firestore) ────────
  // ═══════════════════════════════════════════════════════════════════════════
  Future<bool> seedDataToFirestore() async {
    if (!isFirebaseConnected) return false;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final cat in _categories) {
        batch.set(firestore.collection('categories').doc(cat.id), cat.toMap());
      }
      for (final sh in _sheikhs) {
        batch.set(firestore.collection('sheikhs').doc(sh.id), sh.toMap());
      }
      for (final b in _books) {
        batch.set(firestore.collection('books').doc(b.id), b.toMap());
      }
      for (final s in _series) {
        batch.set(firestore.collection('series').doc(s.id), s.toMap());
      }
      for (final l in _lessons) {
        batch.set(firestore.collection('lessons').doc(l.id), l.toMap());
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error seeding data to Firestore: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 12. التهيئة والحفظ المحلي لبيانات الإدارة والتفضيلات ──────────────────
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _initData() async {
    _initDefaultState();
    await _loadFromPreferences();
  }

  void _initDefaultState() {
    _categories.clear();
    _categories.addAll(MockDataService.categories);

    _sheikhs.clear();
    _sheikhs.addAll(MockDataService.sheikhs);

    _books.clear();
    _books.addAll(MockDataService.books);

    _series.clear();
    _series.addAll(MockDataService.series);

    _lessons.clear();
    _lessons.addAll(MockDataService.lessons);

    recalculateAllCounts();

    if (_lessons.isNotEmpty) {
      _lastPlayedLesson = _lessons.first;
      _lastPlayedSeries = _series.firstWhere(
        (s) => s.id == _lastPlayedLesson!.seriesId,
        orElse: () => _series.first,
      );
      _lastPlayedBook = getBookById(_lastPlayedSeries?.bookId ?? '');
      _lastPlayedSheikh = getSheikhById(_lastPlayedSeries?.sheikhId ?? '');
    }
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // تحميل بيانات المحتوى إن كانت معدلة مسبقاً
      final rawCat = prefs.getString(_keyAdminCategories);
      if (rawCat != null) {
        final List list = jsonDecode(rawCat);
        _categories.clear();
        _categories.addAll(list.map((m) => CategoryModel.fromMap(m as Map<String, dynamic>)));
      }

      final rawSh = prefs.getString(_keyAdminSheikhs);
      if (rawSh != null) {
        final List list = jsonDecode(rawSh);
        _sheikhs.clear();
        _sheikhs.addAll(list.map((m) => SheikhModel.fromMap(m as Map<String, dynamic>)));
      }

      final rawB = prefs.getString(_keyAdminBooks);
      if (rawB != null) {
        final List list = jsonDecode(rawB);
        _books.clear();
        _books.addAll(list.map((m) => BookModel.fromMap(m as Map<String, dynamic>)));
      }

      final rawS = prefs.getString(_keyAdminSeries);
      if (rawS != null) {
        final List list = jsonDecode(rawS);
        _series.clear();
        _series.addAll(list.map((m) => SeriesModel.fromMap(m as Map<String, dynamic>)));
      }

      final rawL = prefs.getString(_keyAdminLessons);
      if (rawL != null) {
        final List list = jsonDecode(rawL);
        _lessons.clear();
        _lessons.addAll(list.map((m) => LessonModel.fromMap(m as Map<String, dynamic>)));
      }

      recalculateAllCounts();

      // تفضيلات الطالب
      final savedSeries = prefs.getStringList(_keyStudiedSeries);
      if (savedSeries != null && savedSeries.isNotEmpty) {
        _studiedSeriesIds.clear();
        _studiedSeriesIds.addAll(savedSeries);
      }
      final savedLessons = prefs.getStringList(_keyCompletedLessons);
      if (savedLessons != null && savedLessons.isNotEmpty) {
        _completedLessonIds.clear();
        _completedLessonIds.addAll(savedLessons);
      }
      final savedName = prefs.getString(_keyUserName);
      if (savedName != null && savedName.isNotEmpty) {
        _userName = savedName;
      }
      final savedFontSize = prefs.getDouble(_keyFontSize);
      if (savedFontSize != null && savedFontSize >= 12.0) {
        _defaultTranscriptFontSize = savedFontSize;
      }
      final savedAutoPlay = prefs.getBool(_keyAutoPlay);
      if (savedAutoPlay != null) {
        _autoPlayNextLesson = savedAutoPlay;
      }
      notifyListeners();
    } catch (_) {
      // الاعتماد على البيانات الافتراضية
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyStudiedSeries, _studiedSeriesIds);
      await prefs.setStringList(_keyCompletedLessons, _completedLessonIds);
      await prefs.setString(_keyUserName, _userName);
      await prefs.setDouble(_keyFontSize, _defaultTranscriptFontSize);
      await prefs.setBool(_keyAutoPlay, _autoPlayNextLesson);
    } catch (_) {}
  }

  Future<void> _saveDataToPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAdminCategories, jsonEncode(_categories.map((c) => c.toMap()).toList()));
      await prefs.setString(_keyAdminSheikhs, jsonEncode(_sheikhs.map((s) => s.toMap()).toList()));
      await prefs.setString(_keyAdminBooks, jsonEncode(_books.map((b) => b.toMap()).toList()));
      await prefs.setString(_keyAdminSeries, jsonEncode(_series.map((s) => s.toMap()).toList()));
      await prefs.setString(_keyAdminLessons, jsonEncode(_lessons.map((l) => l.toMap()).toList()));
    } catch (_) {}
  }
}
