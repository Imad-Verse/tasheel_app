import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tasheel_app/main.dart';
import 'package:tasheel_app/providers/audio_provider.dart';
import 'package:tasheel_app/screens/admin/admin_dashboard_screen.dart';
import 'package:tasheel_app/screens/lesson_player_screen.dart';
import 'package:tasheel_app/services/mock_data_service.dart';
import 'package:tasheel_app/widgets/mini_player_widget.dart';

void main() {
  testWidgets('Tasheel app Stage 4 Audio Player, Mini Player, and Navigation Test',
      (WidgetTester tester) async {
    // 1. تشغيل التطبيق وفحص شاشة البداية
    await tester.pumpWidget(const TasheelApp());
    expect(find.text('تسهيل'), findsOneWidget);

    // 2. انتهاء مدة شاشة البداية (2600ms)
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    // فحص مكونات الصفحة الرئيسية
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('أكمل الاستماع'), findsOneWidget);
    expect(find.text('المحفوظات'), findsOneWidget);

    // 3. فتح مشغل الدرس المتقدم من بطاقة "أكمل الاستماع"
    await tester.tap(find.text('أكمل الاستماع'));
    await tester.pumpAndSettle();

    // التحقق من مكونات مشغل الدرس
    expect(find.text('تفريغ الدرس'), findsOneWidget);
    expect(find.text('+5s'), findsOneWidget);
    expect(find.text('-5s'), findsOneWidget);
    expect(find.text('1.0x'), findsOneWidget);
    expect(find.text('مؤقت النوم'), findsOneWidget);
    expect(find.text('A+'), findsOneWidget);
    expect(find.text('A-'), findsOneWidget);

    // اختبار النقر على أزرار التقديم والتأخير 5 ثوانٍ
    await tester.tap(find.text('+5s'));
    await tester.pump();
    await tester.tap(find.text('-5s'));
    await tester.pump();

    // اختبار نافذة تغيير السرعة
    await tester.tap(find.text('1.0x'));
    await tester.pumpAndSettle();
    expect(find.text('سرعة التشغيل'), findsOneWidget);
    expect(find.text('1.25x'), findsOneWidget);
    await tester.tap(find.text('1.25x'));
    await tester.pumpAndSettle();
    expect(find.text('1.25x'), findsOneWidget);

    // اختبار نافذة مؤقت النوم
    await tester.tap(find.text('مؤقت النوم'));
    await tester.pumpAndSettle();
    expect(find.text('مؤقت النوم (إيقاف الصوت تلقائياً)'), findsOneWidget);
    expect(find.text('15 دقيقة'), findsOneWidget);
    await tester.tap(find.text('15 دقيقة'));
    await tester.pumpAndSettle();

    // إلغاء مؤقت النوم لتجنب وجود مؤقتات معلقة في بيئة الاختبار
    final audioProv = Provider.of<AudioProvider>(
      tester.element(find.byType(LessonPlayerScreen)),
      listen: false,
    );
    audioProv.cancelSleepTimer();
    await tester.pump();

    // اختبار زر البحث في التفريغ النصي
    await tester.tap(find.byTooltip('بحث في التفريغ'));
    await tester.pumpAndSettle();
    expect(find.text('ابحث عن كلمة في نص الدرس...'), findsOneWidget);

    // إدخال كلمة بحث والتحقق
    await tester.enterText(find.byType(TextField), 'التوحيد');
    await tester.pumpAndSettle();

    // إغلاق حقل البحث
    await tester.tap(find.byTooltip('بحث في التفريغ'));
    await tester.pumpAndSettle();

    // اختبار تكبير الخط
    await tester.tap(find.text('A+'));
    await tester.pump();

    // 4. الرجوع إلى الشاشة الرئيسية والتأكد من ظهور المشغل المصغر (MiniPlayerWidget)
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();

    expect(find.byType(MiniPlayerWidget), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsWidgets);

    // اختبار إغلاق المشغل المصغر
    await tester.tap(find.byTooltip('إغلاق المشغل'));
    await tester.pumpAndSettle();
    expect(find.text('إغلاق المشغل'), findsNothing);

    // 5. اختبار درس بدون تفريغ نصي والتأكد من ظهور رسالة الاعتذار وزر واتساب
    final lessonWithoutTranscript = MockDataService.lessons.firstWhere(
      (l) => !l.hasTranscript,
    );
    final seriesForLesson = MockDataService.series.firstWhere(
      (s) => s.id == lessonWithoutTranscript.seriesId,
    );

    // نفتح شاشة الدرس بدون تفريغ
    final navContext = tester.element(find.text('أكمل الاستماع'));
    Navigator.push(
      navContext,
      MaterialPageRoute(
        builder: (_) => LessonPlayerScreen(
          lesson: lessonWithoutTranscript,
          series: seriesForLesson,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ساهم في تفريغ الدرس (عبر واتساب)'), findsOneWidget);
    expect(
      find.textContaining('لم يتم تفريغ الدرس بعد'),
      findsOneWidget,
    );

    // الرجوع إلى الرئيسية
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();

    // 6. مسار المتون: التبويب -> القسم -> تفاصيل الكتاب -> قائمة الدروس
    await tester.tap(find.byIcon(Icons.menu_book_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('جميع المتون العلمية'), findsOneWidget);

    // الضغط على قسم العقيدة لفتح CategoryBooksScreen
    await tester.tap(find.text('العقيدة'));
    await tester.pumpAndSettle();
    expect(find.text('متون العقيدة'), findsOneWidget);
    expect(find.text('كتاب التوحيد'), findsWidgets);

    // الضغط على كتاب التوحيد لفتح BookDetailsScreen
    await tester.tap(find.text('كتاب التوحيد').first);
    await tester.pumpAndSettle();
    expect(find.text('الشيوخ الشارحون للكتاب'), findsOneWidget);
    expect(find.text('المؤلف: الإمام محمد بن عبد الوهاب'), findsOneWidget);

    // الضغط على شرح ابن عثيمين لفتح SeriesLessonsScreen
    await tester.tap(find.text('الشيخ محمد بن صالح العثيمين'));
    await tester.pumpAndSettle();
    expect(find.text('قائمة الدروس العلمية'), findsOneWidget);

    // فحص زر "بدء دراسة هذا المتن"
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    final studyButtonFinder = find.textContaining('بدء دراسة هذا المتن');
    final alreadyStudiedFinder = find.textContaining('مضاف في المحفوظات');

    if (studyButtonFinder.evaluate().isNotEmpty) {
      await tester.tap(studyButtonFinder);
      await tester.pumpAndSettle();
      expect(find.textContaining('مضاف في المحفوظات'), findsOneWidget);
    } else {
      expect(alreadyStudiedFinder, findsOneWidget);
    }

    // الرجوع 3 مرات للعودة إلى الهيكل الرئيسي MainScaffold
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();

    // 7. مسار الشيوخ: التبويب -> تفاصيل الشيخ -> سيرة الشيخ
    await tester.tap(find.byIcon(Icons.person_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('جميع الشيوخ والعلماء'), findsOneWidget);

    // الضغط على الشيخ محمد بن صالح العثيمين لفتح SheikhDetailsScreen
    await tester.tap(find.text('الشيخ محمد بن صالح العثيمين').first);
    await tester.pumpAndSettle();
    expect(find.text('اقرأ السيرة كاملة'), findsOneWidget);
    expect(find.text('الشروحات والمتون المسجلة'), findsOneWidget);

    // الضغط على زر "اقرأ السيرة كاملة"
    await tester.tap(find.text('اقرأ السيرة كاملة'));
    await tester.pumpAndSettle();
    expect(find.text('إغلاق'), findsOneWidget);

    // إغلاق النافذة المنبثقة
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    expect(find.text('اقرأ السيرة كاملة'), findsOneWidget);

    // الرجوع إلى الهيكل الرئيسي MainScaffold
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();

    // ── 8. المرحلة الخامسة: اختبار شاشة المحفوظات (التبويب الرابع) ──────────
    await tester.tap(find.byIcon(Icons.bookmark_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('المتون المحفوظة'), findsOneWidget);
    expect(find.text('المتون قيد الدراسة'), findsOneWidget);
    expect(find.text('متابعة الدراسة'), findsWidgets);

    // اختبار زر متابعة الدراسة
    await tester.tap(find.text('متابعة الدراسة').first);
    await tester.pumpAndSettle();
    expect(find.text('قائمة الدروس العلمية'), findsOneWidget);

    // الرجوع لتبويب المحفوظات
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('المتون المحفوظة'), findsOneWidget);

    // ── 9. المرحلة الخامسة: اختبار شاشة المزيد (التبويب الخامس) ────────────
    await tester.tap(find.byIcon(Icons.menu_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('المزيد'), findsWidgets);
    // التحقق من عدم وجود زر إعدادات الحساب في صفحة المزيد واقتصارها على الاسم والأيقونة
    expect(find.text('إعدادات الحساب'), findsNothing);
    expect(find.text('أبو الحارث عماد بعلول'), findsWidgets);

    // ── اختبار شاشة التنزيلات (DownloadsScreen) ─────────────────────────
    await tester.tap(find.text('التنزيلات'));
    await tester.pumpAndSettle();
    expect(find.text('التنزيلات (بدون إنترنت)'), findsOneWidget);
    expect(find.text('درسان محملان'), findsOneWidget);

    // فتح قائمة الدروس المحملة للشرح
    await tester.tap(find.text('درسان محملان'));
    await tester.pumpAndSettle();
    expect(find.text('استماع'), findsWidgets);

    // الرجوع لشاشة المزيد
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();

    // ── اختبار شاشة الإعدادات (SettingsScreen) وتعديل اسم طالب العلم ────
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('إعدادات التطبيق'), findsOneWidget);
    expect(find.text('اسمك يا طالب العلم'), findsOneWidget);
    expect(find.text('حجم خط التفريغ الافتراضي'), findsOneWidget);
    expect(find.text('مشغل الصوتيات'), findsOneWidget);
    expect(find.text('التشغيل التلقائي للدرس التالي'), findsOneWidget);

    // اختبار تعديل اسم طالب العلم من شاشة الإعدادات
    await tester.enterText(find.byKey(const ValueKey('student_name_field')), 'أبو عبد الرحمن');
    await tester.ensureVisible(find.byKey(const ValueKey('save_student_name_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save_student_name_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('تم حفظ الاسم بنجاح'), findsOneWidget);
    await tester.pumpAndSettle();

    // اختبار زر مسح الذاكرة المؤقتة
    await tester.scrollUntilVisible(
      find.text('مسح الذاكرة المؤقتة'),
      50.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('مسح الذاكرة المؤقتة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('تم مسح الذاكرة المؤقتة بنجاح'), findsOneWidget);

    // الرجوع لشاشة المزيد والتحقق من انعكاس الاسم الجديد فوراً
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('أبو عبد الرحمن'), findsWidgets);

    // ── اختبار شاشة الإحصائيات (StatisticsScreen) ──────────────────────
    await tester.tap(find.text('الإحصائيات'));
    await tester.pumpAndSettle();
    expect(find.text('الإحصائيات والإنجاز'), findsOneWidget);
    expect(find.text('إحصائيات إنجازك'), findsOneWidget);
    expect(find.text('مكتبة تطبيق تسهيل'), findsOneWidget);
    expect(find.text('توزيع الدروس حسب الأقسام'), findsOneWidget);
    expect(find.text('أقسام علمية'), findsOneWidget);

    // الرجوع لشاشة المزيد
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();

    // ── اختبار شاشة عن التطبيق (AboutAppScreen) ─────────────────────────
    await tester.scrollUntilVisible(
      find.text('عن التطبيق'),
      50.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('عن التطبيق'));
    await tester.pumpAndSettle();
    expect(find.text('رسالة تطبيق تسهيل'), findsOneWidget);
    expect(find.text('قنوات التواصل والمتابعة'), findsOneWidget);
    expect(find.text('تيليجرام'), findsOneWidget);
    expect(find.text('من مشاريعنا التقنية والعلمية'), findsOneWidget);
    expect(find.text('منصة متون العلمية'), findsOneWidget);
    expect(find.text('جامع الفتاوى والتأصيل'), findsOneWidget);

    // ── 10. المرحلة السادسة: البوابة السرية ولوحة التحكم السحابية ─────────────
    // النقر 5 نقرات متتالية على الشعار لفتح بوابة الإدارة السرية
    for (int i = 0; i < 5; i++) {
      await tester.tap(find.text('تسهيل'));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    // التحقق من فتح شاشة تسجيل دخول المدير المؤمنة (AdminLoginScreen)
    expect(find.text('بوابة إدارة تطبيق تسهيل'), findsOneWidget);
    expect(find.text('تسجيل الدخول المعتمد للتحكم بالمحتوى العلمي والمزامنة السحابية'), findsOneWidget);
    expect(find.text('البريد الإلكتروني للمدير'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('تسجيل الدخول إلى لوحة الإدارة'), findsOneWidget);
    // التأكد من إزالة زر الدخول السريع
    expect(find.text('دخول سريع للتجربة (بدون حساب)'), findsNothing);

    // الانتقال للوحة التحكم لفحص واجهاتها
    final adminContext = tester.element(find.text('بوابة إدارة تطبيق تسهيل'));
    Navigator.pushReplacement(
      adminContext,
      MaterialPageRoute(
        builder: (_) => const AdminDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // التحقق من مكونات لوحة التحكم (AdminDashboardScreen)
    expect(find.text('لوحة إدارة تسهيل'), findsOneWidget);
    expect(find.text('رفع للسحابة'), findsOneWidget);
    expect(find.text('الأقسام'), findsOneWidget);
    expect(find.text('الشيوخ'), findsOneWidget);
    expect(find.text('الكتب'), findsOneWidget);
    expect(find.text('الشروحات'), findsOneWidget);
    expect(find.text('الدروس'), findsOneWidget);
    expect(find.text('التفريغات'), findsOneWidget);

    // فحص زر رفع البيانات الأولية إلى السحابة
    await tester.tap(find.text('رفع للسحابة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Firebase'), findsWidgets);

    // اختبار التبديل إلى تبويب "الدروس" وفحص ميزة الإضافة الجماعية Bulk Add
    await tester.tap(find.text('الدروس'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة درس فردي'), findsOneWidget);
    expect(find.textContaining('إضافة جماعية Bulk Add'), findsOneWidget);

    // التبديل إلى وضع Bulk Add
    await tester.tap(find.textContaining('إضافة جماعية Bulk Add'));
    await tester.pumpAndSettle();
    expect(find.text('الإضافة الجماعية السريعة (Bulk Import)'), findsOneWidget);

    // اختبار التبديل إلى تبويب "التفريغات" وفحص محرر التفريغات السريعة
    await tester.tap(find.text('التفريغات'));
    await tester.pumpAndSettle();
    expect(find.textContaining('عرض الدروس غير المفرغة فقط'), findsOneWidget);

    // تسجيل الخروج والعودة للتطبيق
    await tester.tap(find.byTooltip('تسجيل الخروج'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('العودة للتطبيق'));
    await tester.pumpAndSettle();

    // الرجوع من شاشة عن التطبيق لشاشة المزيد
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('المزيد'), findsWidgets);
  });

  test('Smart YouTube Video ID extraction tests', () {
    expect(extractYoutubeVideoId('https://www.youtube.com/watch?v=7_i1wN8eS74'), '7_i1wN8eS74');
    expect(extractYoutubeVideoId('https://youtu.be/7_i1wN8eS74?t=10'), '7_i1wN8eS74');
    expect(extractYoutubeVideoId('https://www.youtube.com/embed/7_i1wN8eS74'), '7_i1wN8eS74');
    expect(extractYoutubeVideoId('https://www.youtube.com/v/7_i1wN8eS74'), '7_i1wN8eS74');
    expect(extractYoutubeVideoId('https://www.youtube.com/shorts/7_i1wN8eS74'), '7_i1wN8eS74');
    expect(extractYoutubeVideoId('https://m.youtube.com/watch?v=7_i1wN8eS74'), '7_i1wN8eS74');
    expect(extractYoutubeVideoId('https://www.youtube.com/watch?feature=youtu.be&v=7_i1wN8eS74'), '7_i1wN8eS74');
    expect(extractYoutubeVideoId('https://youtube.com/live/7_i1wN8eS74'), '7_i1wN8eS74');
    expect(extractYoutubeVideoId('7_i1wN8eS74'), '7_i1wN8eS74');
    expect(extractYoutubeVideoId(''), isNull);
    expect(extractYoutubeVideoId('https://example.com/invalid_video.mp4'), isNull);
  });
}
