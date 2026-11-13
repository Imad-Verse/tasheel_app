import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/audio_provider.dart';
import 'screens/splash_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// تطبيق تسهيل - طريقك لتيسير العلوم الشرعية
/// ═══════════════════════════════════════════════════════════════════════════
/// نقطة الدخول الرئيسية للتطبيق.
/// يُهيئ مشغل الصوتيات و Firebase بأمان (Safe Initialization مع Timeout وحماية)،
/// ويضبط Provider لإدارة الحالة، ويحدد الاتجاه RTL الافتراضي لكامل التطبيق.
/// ═══════════════════════════════════════════════════════════════════════════

bool _isAudioBackgroundInitialized = false;

Future<void> _safeInitAudioBackground() async {
  if (_isAudioBackgroundInitialized) return;
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.madoverse.tasheel.channel.audio',
      androidNotificationChannelName: 'تطبيق تسهيل - مشغل الدروس الصوتية',
      androidNotificationChannelDescription: 'شريط التحكم في تشغيل الدروس والشروحات الشرعية',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      notificationColor: const Color(0xFF4A3B32),
    ).timeout(const Duration(seconds: 4));
    _isAudioBackgroundInitialized = true;
    debugPrint('JustAudioBackground initialized successfully.');
  } catch (e) {
    debugPrint('JustAudioBackground safe initialization error/timeout: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تهيئة مشغل الصوتيات للعمل في الخلفية وشاشة القفل بأمان مع مهلة زمنية
  await _safeInitAudioBackground();

  // 2. تهيئة Firebase عبر DefaultFirebaseOptions بأمان مع مهلة زمنية
  bool isFirebaseConnected = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 4));
    isFirebaseConnected = true;
    debugPrint('Firebase initialized successfully with DefaultFirebaseOptions.');
  } catch (e) {
    debugPrint('Firebase safe initialization warning (local mode): $e');
  }

  // 3. ضبط ألوان شريط الحالة
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  } catch (_) {}

  // 4. تشغيل التطبيق دائماً دون تأخير أو توقف
  runApp(TasheelApp(isFirebaseConnected: isFirebaseConnected));
}

class TasheelApp extends StatelessWidget {
  final bool isFirebaseConnected;

  const TasheelApp({
    super.key,
    this.isFirebaseConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(isFirebaseConnected: isFirebaseConnected),
        ),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: MaterialApp(
        // ── مفتاح ScaffoldMessenger الشامل للإشعارات اللحظية ──────────
        scaffoldMessengerKey: AppProvider.scaffoldMessengerKey,

        // ── إعدادات التطبيق ────────────────────────────────────────────
        title: 'تسهيل',
        debugShowCheckedModeBanner: false,

        // ── الثيم ───────────────────────────────────────────────────────
        theme: AppTheme.lightTheme,

        // ── دعم اللغة العربية وتوطين المكونات ──────────────────────────
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [
          Locale('ar', 'SA'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // ── ضبط الاتجاه من اليمين لليسار لكامل التطبيق ────────────────
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },

        // ── الشاشة الابتدائية ─────────────────────────────────────────
        home: const SplashScreen(),
      ),
    );
  }
}
