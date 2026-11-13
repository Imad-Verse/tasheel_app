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
/// يُهيئ Firebase بأمان (Safe Initialization)، ويضبط Provider لإدارة الحالة،
/// ويحدد الاتجاه RTL الافتراضي لكامل التطبيق.
/// ═══════════════════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة مشغل الصوتيات للعمل في الخلفية وشاشة القفل
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.tasheel.tasheel_app.channel.audio',
    androidNotificationChannelName: 'تطبيق تسهيل - مشغل الدروس الصوتية',
    androidNotificationChannelDescription: 'شريط التحكم في تشغيل الدروس والشروحات الشرعية',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
    notificationColor: const Color(0xFF4A3B32),
  );

  // تهيئة Firebase عبر DefaultFirebaseOptions مع معالجة الأخطاء بأمان
  bool isFirebaseConnected = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseConnected = true;
    debugPrint('Firebase initialized successfully with DefaultFirebaseOptions.');
  } catch (e) {
    debugPrint('Firebase not configured yet or platform offline, running in local mode: $e');
  }

  // ضبط ألوان شريط الحالة
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

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
