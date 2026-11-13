import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// مزود الحالة الشامل للتطبيق ولوحة التحكم السحابية (AppProvider)
/// ═══════════════════════════════════════════════════════════════════════════
/// يدير:
/// - حالة الاتصال بـ Firebase أو الحفظ المحلي المستمر في SharedPreferences.
/// - الاستماع اللحظي للإشعارات وتحديثات التطبيق من Cloud Firestore.
/// - البيانات الحية: الأقسام، الشيوخ، الكتب، الشروحات، والدروس.
/// - عمليات الإدارة الكاملة (CRUD) والإضافة الجماعية Bulk Add للدروس.
/// - التحديث التلقائي للعدادات والإحصائيات عبر recalculateAllCounts().
/// - تتبع آخر درس مستمع والمحفوظات وإعدادات التطبيق.
/// ═══════════════════════════════════════════════════════════════════════════
class AppProvider extends ChangeNotifier {
  final bool isFirebaseConnected;

  // مفتاح ScaffoldMessenger العام لعرض التنبيهات العلوية اللحظية للإشعارات
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // إصدار التطبيق الحالي الفعلي (يُجلب تلقائياً عبر PackageInfo)
  String currentAppVersion = '1.0.0';

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
  static const String _keyAboutApp = 'tasheel_about_app_settings';
  static const String _keyNotifications = 'tasheel_admin_notifications';
  static const String _keyReadNotificationIds = 'tasheel_read_notification_ids';
  static const String _keyAppUpdate = 'tasheel_app_update_info';
  static const String _keyLessonNotes = 'tasheel_lesson_notes_list';

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

  // ─── 0.1 إعدادات صفحة عن التطبيق والتواصل والمشاريع ─────────────────────────
  AboutAppModel _aboutApp = AboutAppModel.defaultData();
  AboutAppModel get aboutApp => _aboutApp;

  Future<void> updateAboutAppInfo({
    required String appDescription,
    required String telegramUrl,
    required String facebookUrl,
    required String youtubeUrl,
    required String websiteUrl,
    required String supportWhatsapp,
    required String shareDescription,
    required String shareUrl,
  }) async {
    _aboutApp = _aboutApp.copyWith(
      appDescription: appDescription.trim(),
      telegramUrl: telegramUrl.trim(),
      facebookUrl: facebookUrl.trim(),
      youtubeUrl: youtubeUrl.trim(),
      websiteUrl: websiteUrl.trim(),
      supportWhatsapp: supportWhatsapp.trim(),
      shareDescription: shareDescription.trim(),
      shareUrl: shareUrl.trim(),
    );
    notifyListeners();
    await _saveAboutAppLocally();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('about_app')
            .set(_aboutApp.toMap());
      } catch (e) {
        debugPrint('Firestore update about_app error: $e');
      }
    }
  }

  Future<void> addOurProject(OurProjectModel project) async {
    final currentList = List<OurProjectModel>.from(_aboutApp.projects);
    currentList.add(project);
    _aboutApp = _aboutApp.copyWith(projects: currentList);
    notifyListeners();
    await _saveAboutAppLocally();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('about_app')
            .set(_aboutApp.toMap());
      } catch (e) {
        debugPrint('Firestore add project error: $e');
      }
    }
  }

  Future<void> updateOurProject(OurProjectModel project) async {
    final currentList = List<OurProjectModel>.from(_aboutApp.projects);
    final idx = currentList.indexWhere((p) => p.id == project.id);
    if (idx != -1) {
      currentList[idx] = project;
      _aboutApp = _aboutApp.copyWith(projects: currentList);
      notifyListeners();
      await _saveAboutAppLocally();
      if (isFirebaseConnected) {
        try {
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('about_app')
              .set(_aboutApp.toMap());
        } catch (e) {
          debugPrint('Firestore update project error: $e');
        }
      }
    }
  }

  Future<void> deleteOurProject(String projectId) async {
    final currentList = List<OurProjectModel>.from(_aboutApp.projects);
    currentList.removeWhere((p) => p.id == projectId);
    _aboutApp = _aboutApp.copyWith(projects: currentList);
    notifyListeners();
    await _saveAboutAppLocally();
    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('about_app')
            .set(_aboutApp.toMap());
      } catch (e) {
        debugPrint('Firestore delete project error: $e');
      }
    }
  }

  Future<void> _saveAboutAppLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAboutApp, jsonEncode(_aboutApp.toMap()));
    } catch (_) {}
  }

  // ─── 0.2 إعدادات تحديث التطبيق والإشعارات اللحظية ──────────────────────────
  AppUpdateModel _appUpdateInfo = const AppUpdateModel();
  AppUpdateModel get appUpdateInfo => _appUpdateInfo;

  /// دالة ذكية لمقارنة إصدارات التطبيق (Semantic Versioning)
  static bool compareVersions(String current, String latest) {
    try {
      final currentParts = current
          .split('.')
          .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
          .toList();
      final latestParts = latest
          .split('.')
          .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
          .toList();
      final maxLen = currentParts.length > latestParts.length
          ? currentParts.length
          : latestParts.length;
      for (int i = 0; i < maxLen; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final l = i < latestParts.length ? latestParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  /// هل يتوفر تحديث جديد للتطبيق مقارنة بالإصدار الحالي
  bool get isUpdateAvailable =>
      compareVersions(currentAppVersion, _appUpdateInfo.latestVersion);

  final List<AppNotificationModel> _notifications = [];
  List<AppNotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  final List<String> _readNotificationIds = [];
  List<String> get readNotificationIds =>
      List.unmodifiable(_readNotificationIds);

  /// عدد الإشعارات غير المقروءة
  int get unreadNotificationsCount => _notifications
      .where((n) => !_readNotificationIds.contains(n.id))
      .length;

  /// التحقق إن كان الإشعار مقروءاً
  bool isNotificationRead(String id) => _readNotificationIds.contains(id);

  /// تحديد جميع الإشعارات كمقروءة
  Future<void> markAllNotificationsAsRead() async {
    for (final n in _notifications) {
      if (!_readNotificationIds.contains(n.id)) {
        _readNotificationIds.add(n.id);
      }
    }
    notifyListeners();
    await _saveReadNotificationsLocally();
  }

  /// تحديد إشعار معين كمقروء
  Future<void> markNotificationAsRead(String id) async {
    if (!_readNotificationIds.contains(id)) {
      _readNotificationIds.add(id);
      notifyListeners();
      await _saveReadNotificationsLocally();
    }
  }

  /// إرسال إشعار جديد إلى Firestore ومحلياً
  Future<void> sendNotification({
    required String title,
    required String body,
    String type = 'general',
    String? actionUrl,
  }) async {
    final newNotif = AppNotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      body: body.trim(),
      type: type,
      actionUrl: actionUrl?.trim(),
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, newNotif);
    notifyListeners();
    await _saveNotificationsLocally();

    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(newNotif.id)
            .set(newNotif.toMap());
      } catch (e) {
        debugPrint('Firestore sendNotification error: $e');
      }
    }
  }

  /// حذف إشعار من السجل السحابي والمحلي
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _readNotificationIds.remove(id);
    notifyListeners();
    await _saveNotificationsLocally();
    await _saveReadNotificationsLocally();

    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint('Firestore deleteNotification error: $e');
      }
    }
  }

  /// تحديث معلومات إصدار التطبيق ونشرها للمستخدمين
  Future<void> updateAppVersionInfo(
    AppUpdateModel updateInfo, {
    bool notifyUsers = true,
  }) async {
    _appUpdateInfo = updateInfo;
    notifyListeners();
    await _saveAppUpdateLocally();

    if (isFirebaseConnected) {
      try {
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('app_update')
            .set(updateInfo.toMap());
      } catch (e) {
        debugPrint('Firestore updateAppVersionInfo error: $e');
      }
    }

    if (notifyUsers) {
      await sendNotification(
        title: 'تحديث جديد متوفر (${updateInfo.latestVersion})',
        body: updateInfo.releaseNotes.trim().isNotEmpty
            ? updateInfo.releaseNotes.trim()
            : 'يتوفر إصدار جديد من تطبيق تسهيل، يرجى التحديث للاستفادة من أحدث الميزات والتحسينات.',
        type: 'update',
        actionUrl: updateInfo.downloadUrl.trim().isNotEmpty
            ? updateInfo.downloadUrl.trim()
            : null,
      );
    }
  }

  // ─── 0.4 كناشة الفوائد العلمية المرتبطة بوقت الدرس ─────────────────────────
  final List<LessonNoteModel> _lessonNotes = [];
  List<LessonNoteModel> get lessonNotes => List.unmodifiable(_lessonNotes);

  /// جلب جميع فوائد درس معين مرتبة زمنياً
  List<LessonNoteModel> getNotesForLesson(String lessonId) {
    final list = _lessonNotes.where((n) => n.lessonId == lessonId).toList();
    list.sort((a, b) => a.timestampSeconds.compareTo(b.timestampSeconds));
    return list;
  }

  /// إضافة فائدة جديدة
  Future<void> addLessonNote(LessonNoteModel note) async {
    _lessonNotes.add(note);
    notifyListeners();
    await _saveLessonNotes();
  }

  /// تعديل فائدة موجودة
  Future<void> updateLessonNote(LessonNoteModel note) async {
    final index = _lessonNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _lessonNotes[index] = note;
      notifyListeners();
      await _saveLessonNotes();
    }
  }

  /// حذف فائدة
  Future<void> deleteLessonNote(String id) async {
    _lessonNotes.removeWhere((n) => n.id == id);
    notifyListeners();
    await _saveLessonNotes();
  }

  Future<void> _loadLessonNotes(SharedPreferences prefs) async {
    try {
      final rawNotes = prefs.getString(_keyLessonNotes);
      if (rawNotes != null) {
        final List list = jsonDecode(rawNotes);
        _lessonNotes.clear();
        _lessonNotes.addAll(
          list.map((m) => LessonNoteModel.fromMap(m as Map<String, dynamic>)),
        );
      }
    } catch (e) {
      debugPrint('Error loading lesson notes: $e');
    }
  }

  Future<void> _saveLessonNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_lessonNotes.map((n) => n.toMap()).toList());
      await prefs.setString(_keyLessonNotes, raw);
    } catch (e) {
      debugPrint('Error saving lesson notes: $e');
    }
  }

  // ── مستمعات البث اللحظي السحابي (Real-time Firestore Streams) ──────────────
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _categoriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sheikhsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _booksSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _seriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _lessonsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _aboutAppSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _appUpdateSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationsSub;

  bool _isFirstNotificationsSnapshot = true;
  bool _hasSyncedCategoriesFromCloud = false;
  bool _hasSyncedSheikhsFromCloud = false;
  bool _hasSyncedBooksFromCloud = false;
  bool _hasSyncedSeriesFromCloud = false;
  bool _hasSyncedLessonsFromCloud = false;

  void _startFirestoreListeners() {
    _cancelFirestoreListeners();

    // 1. الاستماع اللحظي لمجموعة الأقسام (categories)
    try {
      _categoriesSub = FirebaseFirestore.instance
          .collection('categories')
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty || _hasSyncedCategoriesFromCloud) {
            _hasSyncedCategoriesFromCloud = true;
            final List<CategoryModel> fetched = [];
            for (final doc in snapshot.docs) {
              try {
                fetched.add(CategoryModel.fromMap(doc.data(), docId: doc.id));
              } catch (e) {
                debugPrint('Error parsing category ${doc.id}: $e');
              }
            }
            _categories.clear();
            _categories.addAll(fetched);
            recalculateAllCounts();
            _validateReferencesAfterSync();
            _saveDataToPersistence();
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Firestore categories stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Firestore categories stream setup error: $e');
    }

    // 2. الاستماع اللحظي لمجموعة الشيوخ (sheikhs)
    try {
      _sheikhsSub = FirebaseFirestore.instance
          .collection('sheikhs')
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty || _hasSyncedSheikhsFromCloud) {
            _hasSyncedSheikhsFromCloud = true;
            final List<SheikhModel> fetched = [];
            for (final doc in snapshot.docs) {
              try {
                fetched.add(SheikhModel.fromMap(doc.data(), docId: doc.id));
              } catch (e) {
                debugPrint('Error parsing sheikh ${doc.id}: $e');
              }
            }
            _sheikhs.clear();
            _sheikhs.addAll(fetched);
            recalculateAllCounts();
            _validateReferencesAfterSync();
            _saveDataToPersistence();
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Firestore sheikhs stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Firestore sheikhs stream setup error: $e');
    }

    // 3. الاستماع اللحظي لمجموعة الكتب (books)
    try {
      _booksSub = FirebaseFirestore.instance
          .collection('books')
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty || _hasSyncedBooksFromCloud) {
            _hasSyncedBooksFromCloud = true;
            final List<BookModel> fetched = [];
            for (final doc in snapshot.docs) {
              try {
                fetched.add(BookModel.fromMap(doc.data(), docId: doc.id));
              } catch (e) {
                debugPrint('Error parsing book ${doc.id}: $e');
              }
            }
            _books.clear();
            _books.addAll(fetched);
            recalculateAllCounts();
            _validateReferencesAfterSync();
            _saveDataToPersistence();
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Firestore books stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Firestore books stream setup error: $e');
    }

    // 4. الاستماع اللحظي لمجموعة الشروحات (series)
    try {
      _seriesSub = FirebaseFirestore.instance
          .collection('series')
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty || _hasSyncedSeriesFromCloud) {
            _hasSyncedSeriesFromCloud = true;
            final List<SeriesModel> fetched = [];
            for (final doc in snapshot.docs) {
              try {
                fetched.add(SeriesModel.fromMap(doc.data(), docId: doc.id));
              } catch (e) {
                debugPrint('Error parsing series ${doc.id}: $e');
              }
            }
            _series.clear();
            _series.addAll(fetched);
            recalculateAllCounts();
            _validateReferencesAfterSync();
            _saveDataToPersistence();
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Firestore series stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Firestore series stream setup error: $e');
    }

    // 5. الاستماع اللحظي لمجموعة الدروس (lessons)
    try {
      _lessonsSub = FirebaseFirestore.instance
          .collection('lessons')
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty || _hasSyncedLessonsFromCloud) {
            _hasSyncedLessonsFromCloud = true;
            final List<LessonModel> fetched = [];
            for (final doc in snapshot.docs) {
              try {
                fetched.add(LessonModel.fromMap(doc.data(), docId: doc.id));
              } catch (e) {
                debugPrint('Error parsing lesson ${doc.id}: $e');
              }
            }
            fetched.sort((a, b) => a.order.compareTo(b.order));
            _lessons.clear();
            _lessons.addAll(fetched);
            recalculateAllCounts();
            _validateReferencesAfterSync();
            _saveDataToPersistence();
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Firestore lessons stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Firestore lessons stream setup error: $e');
    }

    // 6. الاستماع اللحظي لوثيقة إعدادات عن التطبيق والمشاريع (settings/about_app)
    try {
      _aboutAppSub = FirebaseFirestore.instance
          .collection('settings')
          .doc('about_app')
          .snapshots()
          .listen(
        (doc) {
          if (doc.exists && doc.data() != null) {
            _aboutApp = AboutAppModel.fromMap(doc.data()!);
            _saveAboutAppLocally();
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Firestore about_app stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Firestore about_app stream setup error: $e');
    }

    // 7. الاستماع اللحظي لوثيقة تحديثات التطبيق (settings/app_update)
    try {
      _appUpdateSub = FirebaseFirestore.instance
          .collection('settings')
          .doc('app_update')
          .snapshots()
          .listen(
        (doc) {
          if (doc.exists && doc.data() != null) {
            _appUpdateInfo = AppUpdateModel.fromMap(doc.data()!);
            _saveAppUpdateLocally();
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('Firestore app_update stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Firestore app_update stream setup error: $e');
    }

    // 8. الاستماع اللحظي لمجموعة الإشعارات (notifications)
    try {
      _notificationsSub = FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          final List<AppNotificationModel> fetched = [];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              fetched.add(AppNotificationModel.fromMap(data, docId: doc.id));
            } catch (e) {
              debugPrint('Error parsing notification ${doc.id}: $e');
            }
          }
          fetched.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (!_isFirstNotificationsSnapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                try {
                  final data = change.doc.data();
                  if (data != null) {
                    final newNotif =
                        AppNotificationModel.fromMap(data, docId: change.doc.id);
                    if (!_notifications.any((n) => n.id == newNotif.id)) {
                      _showInAppNotificationBanner(newNotif);
                    }
                  }
                } catch (_) {}
              }
            }
          } else {
            _isFirstNotificationsSnapshot = false;
          }

          _notifications.clear();
          _notifications.addAll(fetched);
          _saveNotificationsLocally();
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Firestore notifications listener error: $e');
        },
      );
    } catch (e) {
      debugPrint('Firestore notifications stream setup error: $e');
    }
  }

  /// إلغاء كافة مستمعات البث بأمان لمنع تسرب الذاكرة
  void _cancelFirestoreListeners() {
    _categoriesSub?.cancel();
    _categoriesSub = null;
    _sheikhsSub?.cancel();
    _sheikhsSub = null;
    _booksSub?.cancel();
    _booksSub = null;
    _seriesSub?.cancel();
    _seriesSub = null;
    _lessonsSub?.cancel();
    _lessonsSub = null;
    _aboutAppSub?.cancel();
    _aboutAppSub = null;
    _appUpdateSub?.cancel();
    _appUpdateSub = null;
    _notificationsSub?.cancel();
    _notificationsSub = null;
  }

  /// التحقق من سلامة المراجع وتطهير السجلات بعد كل مزامنة سحابية
  void _validateReferencesAfterSync() {
    // 1. التحقق من سلامة آخر درس تم الاستماع إليه
    if (_lastPlayedLesson != null && !_lessons.any((l) => l.id == _lastPlayedLesson!.id)) {
      if (_lessons.isNotEmpty) {
        _lastPlayedLesson = _lessons.first;
        _lastPlayedSeries = _series.firstWhere(
          (s) => s.id == _lastPlayedLesson!.seriesId,
          orElse: () => _series.isNotEmpty
              ? _series.first
              : const SeriesModel(id: '', bookId: '', sheikhId: '', categoryId: '', title: ''),
        );
        _lastPlayedBook = getBookById(_lastPlayedSeries?.bookId ?? '');
        _lastPlayedSheikh = getSheikhById(_lastPlayedSeries?.sheikhId ?? '');
      } else {
        _lastPlayedLesson = null;
        _lastPlayedSeries = null;
        _lastPlayedBook = null;
        _lastPlayedSheikh = null;
      }
    } else if (_lastPlayedLesson != null) {
      final updatedLesson = getLessonById(_lastPlayedLesson!.id);
      if (updatedLesson != null) {
        _lastPlayedLesson = updatedLesson;
      }
      if (_lastPlayedSeries != null) {
        final updatedSeries = getSeriesById(_lastPlayedSeries!.id);
        if (updatedSeries != null) {
          _lastPlayedSeries = updatedSeries;
        }
      }
    }

    // 2. تنظيف الشروحات المحذوفة من قائمة المحفوظات
    if (_series.isNotEmpty) {
      _studiedSeriesIds.removeWhere((id) => !_series.any((s) => s.id == id));
    }

    // 3. تنظيف الدروس المحذوفة من قائمة الدروس المكتملة
    if (_lessons.isNotEmpty) {
      _completedLessonIds.removeWhere((id) => !_lessons.any((l) => l.id == id));
    }
  }

  /// إظهار تنبيه علوي أنيق مع اهتزاز خفيف عند وصول إشعار جديد أثناء فتح التطبيق
  void _showInAppNotificationBanner(AppNotificationModel notification) {
    HapticFeedback.lightImpact();

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        elevation: 8,
        backgroundColor: AppColors.primaryDarkBrown,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.patternBrown.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.iconGold.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.iconGold,
            size: 24,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.title,
              style: GoogleFonts.readexPro(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textGoldLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: GoogleFonts.readexPro(
                fontSize: 11,
                color: AppColors.textWhite,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
            },
            child: Text(
              'إغلاق',
              style: GoogleFonts.readexPro(
                color: AppColors.textGoldLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // إخفاء التنبيه تلقائياً بعد 4 ثوانٍ
    Future.delayed(const Duration(seconds: 4), () {
      messenger.hideCurrentMaterialBanner();
    });
  }

  Future<void> _saveNotificationsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyNotifications,
        jsonEncode(_notifications.map((n) => n.toMap()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _saveReadNotificationsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyReadNotificationIds, _readNotificationIds);
    } catch (_) {}
  }

  Future<void> _saveAppUpdateLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyAppUpdate,
        jsonEncode(_appUpdateInfo.toMap()),
      );
    } catch (_) {}
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

  /// حذف القسم تتابعياً (Cascading Delete):
  /// يحذف القسم، والكتب التابعة له، والشروحات التابعة لتلك الكتب،
  /// وجميع الدروس والتفريغات التابعة لها، وأي شيخ لا يملك شروحات إلا في هذا القسم.
  Future<void> deleteCategory(String categoryId) async {
    final booksToDelete = _books.where((b) => b.categoryId == categoryId).map((b) => b.id).toSet();
    final seriesToDelete = _series
        .where((s) => s.categoryId == categoryId || booksToDelete.contains(s.bookId))
        .map((s) => s.id)
        .toSet();
    final lessonsToDelete = _lessons
        .where((l) => seriesToDelete.contains(l.seriesId))
        .map((l) => l.id)
        .toSet();

    final sheikhsInThisCategory = _series
        .where((s) => seriesToDelete.contains(s.id))
        .map((s) => s.sheikhId)
        .toSet();
    final sheikhsWithOtherSeries = _series
        .where((s) => !seriesToDelete.contains(s.id))
        .map((s) => s.sheikhId)
        .toSet();
    final sheikhsToDelete = sheikhsInThisCategory.difference(sheikhsWithOtherSeries);

    _categories.removeWhere((c) => c.id == categoryId);
    _books.removeWhere((b) => booksToDelete.contains(b.id));
    _series.removeWhere((s) => seriesToDelete.contains(s.id));
    _lessons.removeWhere((l) => lessonsToDelete.contains(l.id));
    _sheikhs.removeWhere((s) => sheikhsToDelete.contains(s.id));

    _cleanUpAfterDeletion(
      deletedLessonIds: lessonsToDelete,
      deletedSeriesIds: seriesToDelete,
      deletedBookIds: booksToDelete,
      deletedSheikhIds: sheikhsToDelete,
    );

    recalculateAllCounts();
    await _saveDataToPersistence();
    await _savePreferences();

    if (isFirebaseConnected) {
      try {
        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();

        batch.delete(firestore.collection('categories').doc(categoryId));
        for (final bId in booksToDelete) {
          batch.delete(firestore.collection('books').doc(bId));
        }
        for (final sId in seriesToDelete) {
          batch.delete(firestore.collection('series').doc(sId));
        }
        for (final lId in lessonsToDelete) {
          batch.delete(firestore.collection('lessons').doc(lId));
        }
        for (final shId in sheikhsToDelete) {
          batch.delete(firestore.collection('sheikhs').doc(shId));
        }

        await batch.commit();
      } catch (e) {
        debugPrint('Firestore category cascade delete error: $e');
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

  /// حذف الشيخ تتابعياً (Cascading Delete):
  /// يحذف الشيخ، وجميع شروحاته، والدروس والتفريغات التابعة لها،
  /// وأي كتاب لم يعد له أي شرح آخر في التطبيق.
  Future<void> deleteSheikh(String sheikhId) async {
    final seriesToDelete = _series.where((s) => s.sheikhId == sheikhId).map((s) => s.id).toSet();
    final lessonsToDelete = _lessons
        .where((l) => seriesToDelete.contains(l.seriesId))
        .map((l) => l.id)
        .toSet();

    final booksOfThisSheikh = _series
        .where((s) => seriesToDelete.contains(s.id))
        .map((s) => s.bookId)
        .toSet();
    final booksWithOtherSeries = _series
        .where((s) => !seriesToDelete.contains(s.id))
        .map((s) => s.bookId)
        .toSet();
    final booksToDelete = booksOfThisSheikh.difference(booksWithOtherSeries);

    _sheikhs.removeWhere((s) => s.id == sheikhId);
    _series.removeWhere((s) => seriesToDelete.contains(s.id));
    _lessons.removeWhere((l) => lessonsToDelete.contains(l.id));
    _books.removeWhere((b) => booksToDelete.contains(b.id));

    _cleanUpAfterDeletion(
      deletedLessonIds: lessonsToDelete,
      deletedSeriesIds: seriesToDelete,
      deletedBookIds: booksToDelete,
      deletedSheikhIds: {sheikhId},
    );

    recalculateAllCounts();
    await _saveDataToPersistence();
    await _savePreferences();

    if (isFirebaseConnected) {
      try {
        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();

        batch.delete(firestore.collection('sheikhs').doc(sheikhId));
        for (final sId in seriesToDelete) {
          batch.delete(firestore.collection('series').doc(sId));
        }
        for (final lId in lessonsToDelete) {
          batch.delete(firestore.collection('lessons').doc(lId));
        }
        for (final bId in booksToDelete) {
          batch.delete(firestore.collection('books').doc(bId));
        }

        await batch.commit();
      } catch (e) {
        debugPrint('Firestore sheikh cascade delete error: $e');
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

  /// حذف الكتاب تتابعياً (Cascading Delete):
  /// يحذف الكتاب، وجميع شروحاته، والدروس والتفريغات التابعة لتلك الشروحات.
  Future<void> deleteBook(String bookId) async {
    final seriesToDelete = _series.where((s) => s.bookId == bookId).map((s) => s.id).toSet();
    final lessonsToDelete = _lessons
        .where((l) => seriesToDelete.contains(l.seriesId))
        .map((l) => l.id)
        .toSet();

    _books.removeWhere((b) => b.id == bookId);
    _series.removeWhere((s) => seriesToDelete.contains(s.id));
    _lessons.removeWhere((l) => lessonsToDelete.contains(l.id));

    _cleanUpAfterDeletion(
      deletedLessonIds: lessonsToDelete,
      deletedSeriesIds: seriesToDelete,
      deletedBookIds: {bookId},
    );

    recalculateAllCounts();
    await _saveDataToPersistence();
    await _savePreferences();

    if (isFirebaseConnected) {
      try {
        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();

        batch.delete(firestore.collection('books').doc(bookId));
        for (final sId in seriesToDelete) {
          batch.delete(firestore.collection('series').doc(sId));
        }
        for (final lId in lessonsToDelete) {
          batch.delete(firestore.collection('lessons').doc(lId));
        }

        await batch.commit();
      } catch (e) {
        debugPrint('Firestore book cascade delete error: $e');
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

  /// حذف الشرح تتابعياً (Cascading Delete):
  /// يحذف الشرح، وجميع الدروس والتفريغات التابعة له.
  Future<void> deleteSeries(String seriesId) async {
    final lessonsToDelete = _lessons.where((l) => l.seriesId == seriesId).map((l) => l.id).toSet();

    _series.removeWhere((s) => s.id == seriesId);
    _lessons.removeWhere((l) => lessonsToDelete.contains(l.id));

    _cleanUpAfterDeletion(
      deletedLessonIds: lessonsToDelete,
      deletedSeriesIds: {seriesId},
    );

    recalculateAllCounts();
    await _saveDataToPersistence();
    await _savePreferences();

    if (isFirebaseConnected) {
      try {
        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();

        batch.delete(firestore.collection('series').doc(seriesId));
        for (final lId in lessonsToDelete) {
          batch.delete(firestore.collection('lessons').doc(lId));
        }

        await batch.commit();
      } catch (e) {
        debugPrint('Firestore series cascade delete error: $e');
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

  /// حذف الدرس:
  /// يحذف الدرس وتفريغه الصوتي وينظفه من سجلات المشغل والمحفوظات.
  Future<void> deleteLesson(String lessonId) async {
    _lessons.removeWhere((l) => l.id == lessonId);

    _cleanUpAfterDeletion(deletedLessonIds: {lessonId});

    recalculateAllCounts();
    await _saveDataToPersistence();
    await _savePreferences();

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

  /// حذف التفريغ النصي فقط للدرس مع الحفاظ على الملف الصوتي والدرس
  Future<void> deleteLessonTranscript(String lessonId) async {
    final idx = _lessons.indexWhere((l) => l.id == lessonId);
    if (idx != -1) {
      _lessons[idx] = _lessons[idx].copyWith(transcript: '');
      if (_lastPlayedLesson?.id == lessonId) {
        _lastPlayedLesson = _lastPlayedLesson!.copyWith(transcript: '');
      }
      await _saveDataToPersistence();
      notifyListeners();
      if (isFirebaseConnected) {
        try {
          await FirebaseFirestore.instance
              .collection('lessons')
              .doc(lessonId)
              .update({'transcript': ''});
        } catch (e) {
          debugPrint('Firestore transcript delete error: $e');
        }
      }
    }
  }

  /// تنظيف مراجع الدروس والشروحات والكتب المحذوفة من سجلات المشغل والمحفوظات
  void _cleanUpAfterDeletion({
    Set<String> deletedLessonIds = const {},
    Set<String> deletedSeriesIds = const {},
    Set<String> deletedBookIds = const {},
    Set<String> deletedSheikhIds = const {},
  }) {
    if (deletedLessonIds.isNotEmpty) {
      _completedLessonIds.removeWhere((id) => deletedLessonIds.contains(id));
    }
    if (deletedSeriesIds.isNotEmpty) {
      _studiedSeriesIds.removeWhere((id) => deletedSeriesIds.contains(id));
    }

    if (_lastPlayedLesson != null && deletedLessonIds.contains(_lastPlayedLesson!.id)) {
      if (_lessons.isNotEmpty) {
        _lastPlayedLesson = _lessons.first;
        _lastPlayedSeries = _series.firstWhere(
          (s) => s.id == _lastPlayedLesson!.seriesId,
          orElse: () => _series.isNotEmpty
              ? _series.first
              : const SeriesModel(id: '', bookId: '', sheikhId: '', categoryId: '', title: ''),
        );
        _lastPlayedBook = getBookById(_lastPlayedSeries?.bookId ?? '');
        _lastPlayedSheikh = getSheikhById(_lastPlayedSeries?.sheikhId ?? '');
      } else {
        _lastPlayedLesson = null;
        _lastPlayedSeries = null;
        _lastPlayedBook = null;
        _lastPlayedSheikh = null;
      }
    } else {
      if (_lastPlayedSeries != null && deletedSeriesIds.contains(_lastPlayedSeries!.id)) {
        _lastPlayedSeries = null;
      }
      if (_lastPlayedBook != null && deletedBookIds.contains(_lastPlayedBook!.id)) {
        _lastPlayedBook = null;
      }
      if (_lastPlayedSheikh != null && deletedSheikhIds.contains(_lastPlayedSheikh!.id)) {
        _lastPlayedSheikh = null;
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

    final List<LessonModel> newlyAdded = [];

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
      newlyAdded.add(newLesson);
      currentOrder++;
      addedCount++;
    }

    if (addedCount > 0) {
      recalculateAllCounts();
      await _saveDataToPersistence();
      notifyListeners();

      if (isFirebaseConnected && newlyAdded.isNotEmpty) {
        try {
          final firestore = FirebaseFirestore.instance;
          final batch = firestore.batch();
          for (final l in newlyAdded) {
            batch.set(firestore.collection('lessons').doc(l.id), l.toMap());
          }
          await batch.commit();
        } catch (e) {
          debugPrint('Firestore bulkAddLessons batch error: $e');
        }
      }
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

      // تضمين بيانات عن التطبيق والتواصل والمشاريع في السحابة
      batch.set(
        firestore.collection('settings').doc('about_app'),
        _aboutApp.toMap(),
      );

      // تضمين بيانات إصدار وتحديث التطبيق
      batch.set(
        firestore.collection('settings').doc('app_update'),
        _appUpdateInfo.toMap(),
      );

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
    await _loadAppVersion();
    await _loadFromPreferences();
    if (isFirebaseConnected) {
      _startFirestoreListeners();
    }
  }

  /// جلب رقم الإصدار الفعلي للتطبيق تلقائياً عبر PackageInfo
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (packageInfo.version.trim().isNotEmpty) {
        currentAppVersion = packageInfo.version.trim();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error getting package info: $e');
    }
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

      final rawAbout = prefs.getString(_keyAboutApp);
      if (rawAbout != null) {
        final map = jsonDecode(rawAbout);
        _aboutApp = AboutAppModel.fromMap(Map<String, dynamic>.from(map as Map));
      }

      // تحميل الإشعارات وتحديثات التطبيق المحفوظة محلياً
      final rawNotifs = prefs.getString(_keyNotifications);
      if (rawNotifs != null) {
        final List list = jsonDecode(rawNotifs);
        _notifications.clear();
        _notifications.addAll(list.map((m) => AppNotificationModel.fromMap(m as Map<String, dynamic>)));
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      final savedRead = prefs.getStringList(_keyReadNotificationIds);
      if (savedRead != null) {
        _readNotificationIds.clear();
        _readNotificationIds.addAll(savedRead);
      }

      final rawUpdate = prefs.getString(_keyAppUpdate);
      if (rawUpdate != null) {
        final map = jsonDecode(rawUpdate);
        _appUpdateInfo = AppUpdateModel.fromMap(Map<String, dynamic>.from(map as Map));
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

      // تحميل فوائد الدروس المسجلة
      await _loadLessonNotes(prefs);
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

  @override
  void dispose() {
    _cancelFirestoreListeners();
    super.dispose();
  }
}
