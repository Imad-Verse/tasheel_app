import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// ═══════════════════════════════════════════════════════════════════════════
/// خيارات تهيئة Firebase الافتراضية لجميع المنصات (DefaultFirebaseOptions)
/// ═══════════════════════════════════════════════════════════════════════════
/// تتيح الاتصال المباشر بمشروع Firebase:
/// Project ID: tasheel-app-2026
/// ═══════════════════════════════════════════════════════════════════════════
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBmoZUizV7NSTt5BUAmC7cHdQGdit4S-f0',
    appId: '1:220978016273:web:835f158cc8ff6f92e3c1b0',
    messagingSenderId: '220978016273',
    projectId: 'tasheel-app-2026',
    authDomain: 'tasheel-app-2026.firebaseapp.com',
    storageBucket: 'tasheel-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBmoZUizV7NSTt5BUAmC7cHdQGdit4S-f0',
    appId: '1:220978016273:web:835f158cc8ff6f92e3c1b0',
    messagingSenderId: '220978016273',
    projectId: 'tasheel-app-2026',
    authDomain: 'tasheel-app-2026.firebaseapp.com',
    storageBucket: 'tasheel-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmoZUizV7NSTt5BUAmC7cHdQGdit4S-f0',
    appId: '1:220978016273:web:835f158cc8ff6f92e3c1b0',
    messagingSenderId: '220978016273',
    projectId: 'tasheel-app-2026',
    authDomain: 'tasheel-app-2026.firebaseapp.com',
    storageBucket: 'tasheel-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBmoZUizV7NSTt5BUAmC7cHdQGdit4S-f0',
    appId: '1:220978016273:web:835f158cc8ff6f92e3c1b0',
    messagingSenderId: '220978016273',
    projectId: 'tasheel-app-2026',
    authDomain: 'tasheel-app-2026.firebaseapp.com',
    storageBucket: 'tasheel-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBmoZUizV7NSTt5BUAmC7cHdQGdit4S-f0',
    appId: '1:220978016273:web:835f158cc8ff6f92e3c1b0',
    messagingSenderId: '220978016273',
    projectId: 'tasheel-app-2026',
    authDomain: 'tasheel-app-2026.firebaseapp.com',
    storageBucket: 'tasheel-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyBmoZUizV7NSTt5BUAmC7cHdQGdit4S-f0',
    appId: '1:220978016273:web:835f158cc8ff6f92e3c1b0',
    messagingSenderId: '220978016273',
    projectId: 'tasheel-app-2026',
    authDomain: 'tasheel-app-2026.firebaseapp.com',
    storageBucket: 'tasheel-app-2026.firebasestorage.app',
  );
}

