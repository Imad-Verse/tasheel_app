import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/platform_helper.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// خدمة التذكير اليومي بطلب العلم (StudyReminderService)
/// ═══════════════════════════════════════════════════════════════════════════
/// تتولى جدولة تنبيه يومي متكرر لطالب العلم لتذكيره بورده العلمي ومواصلة
/// سلسلة استمراريته (Streak) عبر flutter_local_notifications و timezone.
/// ═══════════════════════════════════════════════════════════════════════════
class StudyReminderService {
  StudyReminderService._internal();
  static final StudyReminderService instance = StudyReminderService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int dailyReminderNotificationId = 1001;
  static const String channelId = 'tasheel_daily_reminder';
  static const String channelName = 'تذكير الورد العلمي اليومي';
  static const String channelDescription = 'تنبيهات يومية لتذكير طالب العلم بمواصلة ورده وسلسلة الاستمرارية';

  /// تهيئة إشعارات النظام والمناطق الزمنية بأمان
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // إنشاء القناة لنظام أندرويد
      if (PlatformHelper.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          const androidChannel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );
          await androidPlugin.createNotificationChannel(androidChannel);
        }
      }

      _isInitialized = true;
      debugPrint('StudyReminderService initialized successfully.');
    } catch (e) {
      debugPrint('StudyReminderService init error: $e');
    }
  }

  /// طلب صلاحيات الإشعارات على أندرويد 13+ و iOS
  Future<bool> requestPermissions() async {
    if (PlatformHelper.isWeb) return false;

    try {
      if (PlatformHelper.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      } else if (PlatformHelper.isIOS || PlatformHelper.isMacOS) {
        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('requestPermissions error: $e');
    }
    return false;
  }

  /// جدولة التذكير اليومي في ساعة ودقيقة محددة
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String? title,
    String? body,
  }) async {
    if (!_isInitialized) await init();

    try {
      // إلغاء أي تذكير سابق أولاً
      await cancelDailyReminder();

      final reminderTitle = title ?? 'حان وقت وردك العلمي 📖';
      final reminderBody = body ?? 'يا طالب العلم، خصص وقتاً لسماع درسك اليومي ومواصلة سلسلة استمرارك.';

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // إذا كان الوقت قد مضى اليوم، نجدوله لليوم التالي
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          sound: 'default',
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        id: dailyReminderNotificationId,
        title: reminderTitle,
        body: reminderBody,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Daily study reminder scheduled at $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('scheduleDailyReminder error: $e');
    }
  }

  /// إلغاء التذكير اليومي
  Future<void> cancelDailyReminder() async {
    try {
      await _notificationsPlugin.cancel(id: dailyReminderNotificationId);
      debugPrint('Daily study reminder cancelled.');
    } catch (e) {
      debugPrint('cancelDailyReminder error: $e');
    }
  }

  /// إظهار إشعار تذكيري فوري (للتجربة أو التنبيه اللحظي)
  Future<void> showInstantReminder({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await init();

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id: dailyReminderNotificationId + 1,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('showInstantReminder error: $e');
    }
  }
}
