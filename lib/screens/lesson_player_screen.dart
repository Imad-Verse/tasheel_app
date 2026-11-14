import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/audio_provider.dart';
import '../services/mock_data_service.dart';
import '../utils/platform_helper.dart';
import '../widgets/decorated_header.dart';
import 'playlists_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// دالة مساعدة ذكية لاستخراج معرف الفيديو (YouTube Video ID)
/// من كافة صيغ روابط يوتيوب الممكنة (watch, youtu.be, embed, shorts, v, live, إلخ)
/// ═══════════════════════════════════════════════════════════════════════════
String? extractYoutubeVideoId(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  // إذا كان الرابط هو المعرف مباشرة بطول 11 محرفاً
  if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
    return trimmed;
  }

  // التعبير النمطي الشامل لكافة صيغ روابط يوتيوب
  final regExp = RegExp(
    r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?(?:.*&)?v=|embed\/|v\/|shorts\/|live\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
  );

  final match = regExp.firstMatch(trimmed);
  if (match != null && match.groupCount >= 1) {
    return match.group(1);
  }

  // كمسار بديل آمن: محاولة قراءة المعلمات بواسطة Uri
  try {
    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      if (uri.queryParameters.containsKey('v')) {
        final v = uri.queryParameters['v'];
        if (v != null && v.length == 11) return v;
      }
      if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        final segment = uri.pathSegments.first;
        if (segment.length == 11) return segment;
      }
    }
  } catch (_) {}

  return null;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة مشغل الدرس والتفريغ النصي التفاعلي (LessonPlayerScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تتضمن:
/// 1. هيدر بني مزخرف مع زر الرجوع، واسم الكتاب والشيخ والدرس الحالي.
/// 2. زر التبديل بين الاستماع الصوتي وفيديو يوتيوب (إن توفر).
/// 3. بطاقة المشغل الصوتي: شريط التقدم، أزرار التشغيل، التقديم/التأخير 5 ثوانٍ،
///    أزرار الدرس السابق/التالي، وأزرار السرعة، تخطي الصمت، مؤقت النوم، والتحميل.
/// 4. بطاقة مشغل الفيديو المدمج (In-App Player) وأزرار الانتقال الخارجي.
/// 5. قسم التفريغ النصي التفاعلي:
///    - إذا توفر: تكبير/تصغير الخط، وحقل بحث فوري مع تظليل الكلمات المطابقة.
///    - إذا لم يتوفر: بطاقة الاعتذار وزر المساهمة في التفريغ عبر واتساب مباشرة.
/// ═══════════════════════════════════════════════════════════════════════════
class LessonPlayerScreen extends StatefulWidget {
  final LessonModel lesson;
  final SeriesModel series;
  final String? initialSearchQuery;

  const LessonPlayerScreen({
    super.key,
    required this.lesson,
    required this.series,
    this.initialSearchQuery,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  // وضع العرض: 0 = استماع صوتي، 1 = مشاهدة فيديو يوتيوب
  int _selectedMediaMode = 0;

  // متحكم مشغل يوتيوب المدمج والمعرف المحمّل حالياً
  YoutubePlayerController? _youtubeController;
  String? _currentLoadedVideoId;

  // خيارات التفريغ النصي
  double _transcriptFontSize = 17.0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();

    // تفعيل البحث وتظليله إذا تم فتح الشاشة من نتائج بحث التفريغ
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.trim().isNotEmpty) {
      _isSearchVisible = true;
      _searchQuery = widget.initialSearchQuery!.trim();
      _searchController.text = _searchQuery;
    }

    // تهيئة الصوت فور فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      if (audioProvider.currentLesson?.id != widget.lesson.id) {
        audioProvider.loadAndPlayLesson(
          lesson: widget.lesson,
          series: widget.series,
          autoPlay: true,
        );
      }
    });
  }

  /// تهيئة متحكم يوتيوب للمعرف المعطى مع حماية كاملة من الأخطاء
  void _initYoutubeController(String videoId) {
    if (_currentLoadedVideoId == videoId && _youtubeController != null) {
      return;
    }
    _disposeYoutubeController();
    _currentLoadedVideoId = videoId;
    try {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          playsInline: true,
          strictRelatedVideos: true,
          captionLanguage: 'ar',
          color: 'red',
        ),
      );
    } catch (e) {
      debugPrint('تعذر تهيئة مشغل يوتيوب: $e');
      _youtubeController = null;
    }
  }

  /// إغلاق وتفريغ متحكم مشغل يوتيوب بالكامل لمنع تسرب الذاكرة وبقاء الصوت في الخلفية
  void _disposeYoutubeController() {
    if (_youtubeController != null) {
      try {
        _youtubeController!.close();
      } catch (_) {}
      _youtubeController = null;
      _currentLoadedVideoId = null;
    }
  }

  /// تبديل وضع الوسائط بين الاستماع الصوتي ومشاهدة الفيديو وقراءة الـ PDF
  void _onMediaModeChanged(int newMode, LessonModel currentLesson) {
    if (_selectedMediaMode == newMode) return;

    if (newMode == 1) {
      // 1. إيقاف المشغل الصوتي فور التبديل لوضع الفيديو حتى لا يتداخل الصوتين وتتوقف خدمة الخلفية
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      audioProvider.pause();

      // 2. تهيئة مشغل يوتيوب الداخلي
      final videoId = extractYoutubeVideoId(currentLesson.videoUrl);
      if (videoId != null) {
        _initYoutubeController(videoId);
      }
    } else {
      // 3. تفريغ وإغلاق مشغل الفيديو عند العودة إلى وضع "الاستماع الصوتي" أو "عارض PDF"
      _disposeYoutubeController();
    }

    setState(() {
      _selectedMediaMode = newMode;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _disposeYoutubeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);

    // استخدام الدرس الحالي من المزود إذا كان نفس السلسلة، لتحديث الشاشة عند الانتقال للتالي/السابق مع دعم التحديثات اللحظية
    final baseLesson =
        (audioProvider.currentSeries?.id == widget.series.id &&
            audioProvider.currentLesson != null)
        ? audioProvider.currentLesson!
        : widget.lesson;
    final currentLesson =
        appProvider.getLessonById(baseLesson.id) ?? baseLesson;

    final currentSeries =
        appProvider.getSeriesById(widget.series.id) ?? widget.series;
    final book =
        appProvider.getBookById(currentSeries.bookId) ??
        MockDataService.getBookById(currentSeries.bookId);
    final sheikh =
        appProvider.getSheikhById(currentSeries.sheikhId) ??
        MockDataService.getSheikhById(currentSeries.sheikhId);
    final hasVideo = currentLesson.hasVideo;

    // استخراج رابط الـ PDF المتاح سواء للدرس أو للشرح ككل
    final lessonPdf = currentLesson.pdfUrl?.trim();
    final seriesPdf = currentSeries.pdfUrl?.trim();
    final effectivePdfUrl = (lessonPdf != null && lessonPdf.isNotEmpty)
        ? lessonPdf
        : ((seriesPdf != null && seriesPdf.isNotEmpty) ? seriesPdf : null);
    final bool hasPdf = effectivePdfUrl != null && effectivePdfUrl.isNotEmpty;

    // إذا تم الانتقال لدرس لا يحتوي على فيديو، العودة التلقائية لوضع الصوت
    if (!hasVideo && _selectedMediaMode == 1) {
      _selectedMediaMode = 0;
      _disposeYoutubeController();
    }
    // إذا كان وضع الـ PDF مختاراً ولا يوجد ملف، العودة للصوت
    if (!hasPdf && _selectedMediaMode == 2) {
      _selectedMediaMode = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // ── 1. الهيدر العلوي المزخرف ومعلومات الدرس ─────────────────────
              _buildPlayerHeader(context, currentLesson, book, sheikh),

              // ── 2. محتوى المشغل والقسم السفلي ────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── كبسولة التبديل (صوت / فيديو يوتيوب / PDF) إن توفر ───
                      if (hasVideo || hasPdf) ...[
                        _buildMediaToggleCapsule(currentLesson, hasVideo, hasPdf),
                        const SizedBox(height: 14),
                      ],

                      // ── عرض بطاقة الفيديو أو بطاقة عارض الـ PDF أو بطاقة المشغل الصوتي ──
                      if (_selectedMediaMode == 1 && hasVideo)
                        _buildYouTubeCard(currentLesson, book, sheikh)
                      else if (_selectedMediaMode == 2 && hasPdf)
                        _buildIntegratedPdfView(
                          context,
                          effectivePdfUrl,
                          currentLesson,
                          currentSeries,
                          book,
                          sheikh,
                          audioProvider,
                          appProvider,
                        )
                      else
                        _buildAudioPlayerCard(
                          context,
                          currentLesson,
                          audioProvider,
                          appProvider,
                          currentSeries,
                          book,
                          sheikh,
                        ),

                      const SizedBox(height: 20),

                      // ── قسم فوائد الدرس (كناشة الفوائد) ─────────────────────
                      _buildLessonNotesCard(
                        context,
                        currentLesson,
                        audioProvider,
                        appProvider,
                        book,
                        sheikh,
                      ),

                      const SizedBox(height: 20),

                      // ── قسم التفريغ النصي أسفل المشغل ───────────────────────
                      _buildTranscriptCard(
                        context,
                        currentLesson,
                        book,
                        sheikh,
                        appProvider,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// الهيدر العلوي: زر الرجوع على اليمين، اسم الكتاب والشارح وعنوان الدرس
  Widget _buildPlayerHeader(
    BuildContext context,
    LessonModel lesson,
    BookModel? book,
    SheikhModel? sheikh,
  ) {
    return DecoratedHeader(
      title: lesson.title,
      showSearchIcon: false,
      onBackPressed: () => Navigator.pop(context),
      customTitleWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${book?.title ?? ""} • ${sheikh?.name ?? ""}',
            style: GoogleFonts.readexPro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textGoldLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 2),
          Text(
            lesson.title,
            style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textWhite,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  /// كبسولة التبديل بين الاستماع الصوتي وفيديو يوتيوب وقراءة الـ PDF
  Widget _buildMediaToggleCapsule(
    LessonModel currentLesson,
    bool hasVideo,
    bool hasPdf,
  ) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleItem(
                title: 'استماع صوتي',
                icon: Icons.headphones_rounded,
                isSelected: _selectedMediaMode == 0,
                onTap: () => _onMediaModeChanged(0, currentLesson),
              ),
              if (hasVideo)
                _buildToggleItem(
                  title: 'مشاهدة فيديو',
                  icon: Icons.ondemand_video_rounded,
                  isSelected: _selectedMediaMode == 1,
                  onTap: () => _onMediaModeChanged(1, currentLesson),
                ),
              if (hasPdf)
                _buildToggleItem(
                  title: 'الكتاب / المتن (PDF)',
                  icon: Icons.picture_as_pdf_rounded,
                  isSelected: _selectedMediaMode == 2,
                  onTap: () => _onMediaModeChanged(2, currentLesson),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDarkBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.textGoldLight
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.readexPro(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textWhite
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة فيديو يوتيوب المدمجة مع زر الانتقال الخارجي
  Widget _buildYouTubeCard(
    LessonModel lesson,
    BookModel? book,
    SheikhModel? sheikh,
  ) {
    final videoId = extractYoutubeVideoId(lesson.videoUrl);

    // التحقق من توافق المتحكم مع المعرف الحالي للدرس
    if (videoId != null && _currentLoadedVideoId != videoId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedMediaMode == 1) {
          _initYoutubeController(videoId);
          setState(() {});
        }
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── المشغل الداخلي الاحترافي بنسبة 16:9 وبحواف دائرية 16 وإطار ذهبي/بني ──
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentGoldBeige, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDarkBrown.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.5),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _youtubeController != null && videoId != null
                    ? YoutubePlayer(
                        controller: _youtubeController!,
                        aspectRatio: 16 / 9,
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.ondemand_video_rounded,
                                color: AppColors.textGoldLight,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                videoId != null ? 'جاري تجهيز مشغل الفيديو...' : 'يتوفر تسجيل لهذا الدرس، يمكنك فتحه عبر الزر أدناه',
                                style: GoogleFonts.readexPro(
                                  fontSize: 12,
                                  color: AppColors.textWhite,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── زر الانتقال لتطبيق اليوتيوب الخارجي ───────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // إيقاف الفيديو الداخلي مؤقتاً فور فتح التطبيق الخارجي
                try {
                  await _youtubeController?.pauseVideo();
                } catch (_) {}

                if (lesson.videoUrl.isNotEmpty) {
                  final uri = Uri.parse(lesson.videoUrl);
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      await launchUrl(uri);
                    }
                  } catch (_) {
                    try {
                      await launchUrl(uri);
                    } catch (_) {}
                  }
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(
                'مشاهدة الدرس على اليوتوب',
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ── شريط التكرار الذكي للمقاطع (A-B Repeat Loop) ───────────────────────────
  Widget _buildABRepeatBar(BuildContext context, AudioProvider audioProvider) {
    final hasA = audioProvider.loopPointA != null;
    final hasB = audioProvider.loopPointB != null;
    final isLooping = audioProvider.isLoopActive;
    final curPos = audioProvider.currentPosition;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLooping
            ? AppColors.primaryDarkBrown.withValues(alpha: 0.05)
            : AppColors.scaffoldCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLooping
              ? AppColors.primaryDarkBrown
              : AppColors.accentGoldBeige.withValues(alpha: 0.5),
          width: isLooping ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── السطر العلوي: العنوان وحالة التكرار وزر التصفير ───────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.repeat_one_rounded,
                    size: 18,
                    color: isLooping
                        ? AppColors.primaryDarkBrown
                        : AppColors.iconGold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'التكرار الذكي (A-B Loop)',
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDarkBrown,
                    ),
                  ),
                ],
              ),
              if (hasA || hasB)
                InkWell(
                  onTap: () {
                    audioProvider.resetLoop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم إلغاء التكرار والعودة للتشغيل العادي', style: GoogleFonts.readexPro()),
                        backgroundColor: AppColors.primaryDarkBrown,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          'إلغاء التكرار',
                          style: GoogleFonts.readexPro(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ── سطر أزرار A و B ───────────────────────────────────────────
          Row(
            children: [
              // زر نقطة البداية A
              Expanded(
                child: InkWell(
                  onTap: () {
                    audioProvider.setLoopPointA();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم ضبط نقطة البداية (A) عند ${_formatDuration(audioProvider.loopPointA!)}',
                          style: GoogleFonts.readexPro(),
                        ),
                        backgroundColor: AppColors.primaryDarkBrown,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: hasA
                          ? AppColors.primaryDarkBrown
                          : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasA
                            ? AppColors.primaryDarkBrown
                            : AppColors.dividerLight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hasA
                              ? 'A: ${_formatDuration(audioProvider.loopPointA!)}'
                              : 'تحديد نقطة (A)',
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasA
                                ? AppColors.textGoldLight
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // زر نقطة النهاية B
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (!hasA) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'يرجى تحديد نقطة البداية (A) أولاً',
                            style: GoogleFonts.readexPro(),
                          ),
                          backgroundColor: Colors.red.shade800,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    if (curPos <= audioProvider.loopPointA!) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'يجب أن تكون نقطة النهاية (B) بعد نقطة البداية (A)',
                            style: GoogleFonts.readexPro(),
                          ),
                          backgroundColor: Colors.red.shade800,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    audioProvider.setLoopPointB();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم ضبط نقطة النهاية (B) عند ${_formatDuration(audioProvider.loopPointB!)} وبدء التكرار',
                          style: GoogleFonts.readexPro(),
                        ),
                        backgroundColor: AppColors.primaryDarkBrown,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: hasB
                          ? AppColors.primaryDarkBrown
                          : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasB
                            ? AppColors.primaryDarkBrown
                            : AppColors.dividerLight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hasB
                              ? 'B: ${_formatDuration(audioProvider.loopPointB!)}'
                              : 'تحديد نقطة (B)',
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasB
                                ? AppColors.textGoldLight
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── سطر خيارات عدد مرات التكرار والعداد الحالي ─────────────────
          Row(
            children: [
              Text(
                'المرات:',
                style: GoogleFonts.readexPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildRepeatCountChip(3, '3 مرات', audioProvider),
                    _buildRepeatCountChip(5, '5 مرات', audioProvider),
                    _buildRepeatCountChip(10, '10 مرات', audioProvider),
                    _buildRepeatCountChip(0, '∞ دائم', audioProvider),
                  ],
                ),
              ),
              if (isLooping) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldBeige.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.iconGold),
                  ),
                  child: Text(
                    audioProvider.loopTargetCount > 0
                        ? '${audioProvider.loopCurrentCount + 1} / ${audioProvider.loopTargetCount}'
                        : '${audioProvider.loopCurrentCount + 1} (∞)',
                    style: GoogleFonts.readexPro(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDarkBrown,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatCountChip(int count, String label, AudioProvider audioProvider) {
    final isSelected = audioProvider.loopTargetCount == count;
    return InkWell(
      onTap: () => audioProvider.setLoopTargetCount(count),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDarkBrown : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryDarkBrown : AppColors.dividerLight,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.readexPro(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.textGoldLight : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// ── عارض كتب ومتون PDF المدمج بجانب المشغل الصوتي ────────────────────
  Widget _buildIntegratedPdfView(
    BuildContext context,
    String pdfUrl,
    LessonModel lesson,
    SeriesModel currentSeries,
    BookModel? book,
    SheikhModel? sheikh,
    AudioProvider audioProvider,
    AppProvider appProvider,
  ) {
    final title = book?.title ?? currentSeries.title;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── شريط رأس عارض الـ PDF ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'متن / كتاب الدرس (PDF)',
                          style: GoogleFonts.readexPro(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkBrown,
                          ),
                        ),
                        Text(
                          title,
                          style: GoogleFonts.readexPro(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                // زر توسيع القراءة لملء الشاشة
                ElevatedButton.icon(
                  onPressed: () {
                    _openFullScreenPdf(context, pdfUrl, title, audioProvider);
                  },
                  icon: const Icon(Icons.fullscreen_rounded, size: 16),
                  label: Text('ملء الشاشة', style: GoogleFonts.readexPro(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkBrown,
                    foregroundColor: AppColors.textGoldLight,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.dividerLight),

          // ── عارض الـ PDF الداخلي ──────────────────────────────────
          SizedBox(
            height: 480,
            child: ClipRRect(
              child: SfPdfViewer.network(
                pdfUrl,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                enableDoubleTapZooming: true,
                onDocumentLoadFailed: (details) {
                  debugPrint('PDF load error: ${details.description}');
                },
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.dividerLight),

          // ── شريط التحكم بالصوت والتكرار A-B المدمج أسفل الـ PDF ──────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ميزة التكرار الذكي A-B أثناء القراءة
                _buildABRepeatBar(context, audioProvider),

                const SizedBox(height: 12),

                // شريط الوقت والتقدم وأزرار التحكم بالصوت
                _buildMiniAudioControls(context, lesson, audioProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// شريط تحكم مصغر بالصوت لعارض الـ PDF
  Widget _buildMiniAudioControls(
    BuildContext context,
    LessonModel lesson,
    AudioProvider audioProvider,
  ) {
    final currentPos = audioProvider.currentPosition;
    final totalDur = audioProvider.totalDuration;
    final maxMs = totalDur.inMilliseconds.toDouble();
    final curMs = currentPos.inMilliseconds.toDouble().clamp(
          0.0,
          maxMs > 0 ? maxMs : 1.0,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        children: [
          // شريط السلايدر
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryDarkBrown,
              inactiveTrackColor: AppColors.dividerLight,
              thumbColor: AppColors.primaryDarkBrown,
              overlayColor: AppColors.accentGoldBeige.withValues(alpha: 0.2),
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              min: 0.0,
              max: maxMs > 0 ? maxMs : 1.0,
              value: curMs,
              onChanged: (val) {
                audioProvider.seek(Duration(milliseconds: val.toInt()));
              },
            ),
          ),
          // الأوقات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(currentPos),
                  style: GoogleFonts.readexPro(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatDuration(totalDur.inSeconds > 0 ? totalDur : _parseDurationString(lesson.duration)),
                  style: GoogleFonts.readexPro(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 24,
                color: audioProvider.hasPreviousLesson ? AppColors.primaryDarkBrown : AppColors.dividerLight,
                onPressed: audioProvider.hasPreviousLesson ? () => audioProvider.playPreviousLesson() : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.replay_5_rounded),
                iconSize: 26,
                color: AppColors.primaryDarkBrown,
                onPressed: () => audioProvider.seekBackward5s(),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => audioProvider.togglePlayPause(),
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkBrown,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDarkBrown.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: audioProvider.isBuffering
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textGoldLight),
                            ),
                          )
                        : Icon(
                            audioProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: AppColors.textGoldLight,
                            size: 30,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.forward_5_rounded),
                iconSize: 26,
                color: AppColors.primaryDarkBrown,
                onPressed: () => audioProvider.seekForward5s(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 24,
                color: audioProvider.hasNextLesson ? AppColors.primaryDarkBrown : AppColors.dividerLight,
                onPressed: audioProvider.hasNextLesson ? () => audioProvider.playNextLesson() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openFullScreenPdf(
    BuildContext context,
    String pdfUrl,
    String title,
    AudioProvider audioProvider,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenPdfScreen(
          pdfUrl: pdfUrl,
          title: title,
        ),
      ),
    );
  }

  /// ── 2. بطاقة المشغل الصوتي وأزرار التحكم ────────────────────────────────
  Widget _buildAudioPlayerCard(
    BuildContext context,
    LessonModel lesson,
    AudioProvider audioProvider,
    AppProvider appProvider,
    SeriesModel currentSeries,
    BookModel? book,
    SheikhModel? sheikh,
  ) {
    final currentPos = audioProvider.currentPosition;
    final totalDur = audioProvider.totalDuration;
    final maxMs = totalDur.inMilliseconds.toDouble();
    final curMs = currentPos.inMilliseconds.toDouble().clamp(
      0.0,
      maxMs > 0 ? maxMs : 1.0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── شريط التقدم ──────────────────────────────────────────
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryDarkBrown,
              inactiveTrackColor: AppColors.dividerLight,
              thumbColor: AppColors.primaryDarkBrown,
              overlayColor: AppColors.accentGoldBeige.withValues(alpha: 0.2),
              trackHeight: 4.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              min: 0.0,
              max: maxMs > 0 ? maxMs : 1.0,
              value: curMs,
              onChanged: (val) {
                audioProvider.seek(Duration(milliseconds: val.toInt()));
              },
            ),
          ),

          // الوقت المنقضي والوقت الكلي (يمين: المنقضي، يسار: الكلي في RTL)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(currentPos),
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _formatDuration(
                    totalDur.inSeconds > 0
                        ? totalDur
                        : _parseDurationString(lesson.duration),
                  ),
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── شريط فواصل الاستماع (العلامات المرجعية الصوتية) ─────────
          _buildAudioBookmarksRow(context, audioProvider, appProvider, lesson),

          const SizedBox(height: 14),

          // ── صف أزرار التشغيل الأساسية ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الدرس السابق
              IconButton(
                tooltip: 'الدرس السابق',
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 28,
                color: audioProvider.hasPreviousLesson
                    ? AppColors.primaryDarkBrown
                    : AppColors.dividerLight,
                onPressed: audioProvider.hasPreviousLesson
                    ? () => audioProvider.playPreviousLesson()
                    : null,
              ),

              const SizedBox(width: 8),

              // تأخير 5 ثوانٍ (-5s)
              InkWell(
                onTap: () => audioProvider.seekBackward5s(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.replay_5_rounded,
                        color: AppColors.primaryDarkBrown,
                        size: 30,
                      ),
                      Text(
                        '-5s',
                        style: GoogleFonts.readexPro(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // زر التشغيل والإيقاف المؤقت الرئيسي في المنتصف
              InkWell(
                onTap: () => audioProvider.togglePlayPause(),
                borderRadius: BorderRadius.circular(35),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkBrown,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDarkBrown.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: audioProvider.isBuffering
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textGoldLight,
                              ),
                            ),
                          )
                        : Icon(
                            audioProvider.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.textGoldLight,
                            size: 40,
                          ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // تقديم 5 ثوانٍ (+5s)
              InkWell(
                onTap: () => audioProvider.seekForward5s(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.forward_5_rounded,
                        color: AppColors.primaryDarkBrown,
                        size: 30,
                      ),
                      Text(
                        '+5s',
                        style: GoogleFonts.readexPro(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // الدرس التالي
              IconButton(
                tooltip: 'الدرس التالي',
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 28,
                color: audioProvider.hasNextLesson
                    ? AppColors.primaryDarkBrown
                    : AppColors.dividerLight,
                onPressed: audioProvider.hasNextLesson
                    ? () => audioProvider.playNextLesson()
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.dividerLight, height: 1),
          const SizedBox(height: 12),

          // ── شريط التكرار الذكي للمقاطع (A-B Repeat Loop) ──────────────
          _buildABRepeatBar(context, audioProvider),

          const SizedBox(height: 14),
          const Divider(color: AppColors.dividerLight, height: 1),
          const SizedBox(height: 14),

          // ── سطر ضوابط المشغل الأساسية (السرعة، تخطي الصمت، مؤقت النوم، التحميل) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. زر السرعة
              _buildToolCapsule(
                icon: Icons.speed_rounded,
                label: '${audioProvider.playbackSpeed}x',
                isActive: audioProvider.playbackSpeed != 1.0,
                onTap: () => _openSpeedBottomSheet(context, audioProvider),
              ),

              // 2. زر تخطي الصمت
              _buildToolCapsule(
                icon: Icons.volume_off_rounded,
                label: 'تخطي الصمت',
                isActive: audioProvider.isSkipSilenceEnabled,
                onTap: () async {
                  final success = await audioProvider.toggleSkipSilence();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? (audioProvider.isSkipSilenceEnabled
                                  ? 'تم تفعيل تخطي الصمت'
                                  : 'تم إلغاء تخطي الصمت')
                            : 'ميزة تخطي الصمت مدعومة على تطبيق الهواتف فقط',
                        style: GoogleFonts.readexPro(),
                      ),
                      backgroundColor: AppColors.primaryDarkBrown,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // 3. زر مؤقت النوم
              _buildToolCapsule(
                icon: Icons.bedtime_rounded,
                label: audioProvider.hasActiveSleepTimer
                    ? (audioProvider.sleepAtEndOfLesson
                        ? 'نهاية الدرس'
                        : (audioProvider.remainingSleepTime != null
                            ? _formatDuration(audioProvider.remainingSleepTime!)
                            : 'مؤقت نشط'))
                    : 'مؤقت النوم',
                isActive: audioProvider.hasActiveSleepTimer,
                onTap: () => _openSleepTimerBottomSheet(context, audioProvider),
              ),

              // 4. زر التحميل
              _buildToolCapsule(
                icon: audioProvider.isDownloaded(lesson.id)
                    ? Icons.download_done_rounded
                    : audioProvider.isDownloading(lesson.id)
                    ? Icons.downloading_rounded
                    : Icons.download_rounded,
                label: audioProvider.isDownloaded(lesson.id)
                    ? 'تم التحميل'
                    : audioProvider.isDownloading(lesson.id)
                    ? '${(audioProvider.getDownloadProgress(lesson.id) * 100).toInt()}%'
                    : 'تحميل',
                isActive: audioProvider.isDownloaded(lesson.id),
                onTap: () {
                  if (PlatformHelper.isWeb) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'التحميل للاستماع دون إنترنت متاح عبر تطبيق الهاتف والحاسوب',
                          style: GoogleFonts.readexPro(),
                        ),
                        backgroundColor: AppColors.primaryDarkBrown,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  audioProvider.toggleDownload(lesson.id, lesson: lesson);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        audioProvider.isDownloaded(lesson.id)
                            ? 'تمت إزالة الدرس من التنزيلات'
                            : 'تمت إضافة الدرس للتنزيلات (للاستماع بدون إنترنت)',
                        style: GoogleFonts.readexPro(),
                      ),
                      backgroundColor: AppColors.primaryDarkBrown,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: AppColors.dividerLight, height: 1),
          const SizedBox(height: 10),

          // ── سطر أدوات طالب العلم (تدوين فائدة، فاصل سماع، إضافة لقائمة) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. زر تدوين فائدة (كناشة الفوائد)
              _buildToolCapsule(
                icon: Icons.edit_note_rounded,
                label: 'تدوين فائدة',
                isActive: false,
                onTap: () => _openAddNoteDialog(
                  context,
                  audioProvider,
                  appProvider,
                  lesson,
                  book,
                  sheikh,
                ),
              ),

              // 2. زر إضافة فاصل سماع (علامة مرجعية صوتية)
              _buildToolCapsule(
                icon: Icons.bookmark_add_rounded,
                label: 'فاصل سماع',
                isActive: false,
                onTap: () => _openAddBookmarkDialog(
                  context,
                  audioProvider,
                  appProvider,
                  lesson,
                ),
              ),

              // 3. زر إضافة لقائمة تشغيل
              _buildToolCapsule(
                icon: Icons.playlist_add_rounded,
                label: 'إضافة لقائمة',
                isActive: false,
                onTap: () => PlaylistsScreen.showAddToPlaylistBottomSheet(
                  context,
                  lesson,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── صف أزرار التنقل السريع بين الدروس (الدرس التالي، قائمة الدروس، الدرس السابق) ──
          _buildQuickNavigationRow(
            context: context,
            currentLesson: lesson,
            currentSeries: currentSeries,
            book: book,
            sheikh: sheikh,
            audioProvider: audioProvider,
            appProvider: appProvider,
          ),
        ],
      ),
    );
  }

  /// ── صف أزرار التنقل السريع بين الدروس ─────────────────────────────────────
  Widget _buildQuickNavigationRow({
    required BuildContext context,
    required LessonModel currentLesson,
    required SeriesModel currentSeries,
    required BookModel? book,
    required SheikhModel? sheikh,
    required AudioProvider audioProvider,
    required AppProvider appProvider,
  }) {
    // جلب قائمة دروس الشرح الحالي مرتبة حسب order
    final seriesLessons =
        appProvider.getLessonsBySeries(currentSeries.id).isNotEmpty
        ? appProvider.getLessonsBySeries(currentSeries.id)
        : MockDataService.getLessonsBySeries(currentSeries.id);

    int currentIndex = seriesLessons.indexWhere(
      (l) => l.id == currentLesson.id,
    );
    if (currentIndex == -1) {
      currentIndex = seriesLessons.indexWhere(
        (l) => l.order == currentLesson.order,
      );
    }

    final hasNextLesson =
        currentIndex != -1 && currentIndex < seriesLessons.length - 1;
    final nextLesson = hasNextLesson ? seriesLessons[currentIndex + 1] : null;

    final hasPreviousLesson = currentIndex > 0;
    final prevLesson = hasPreviousLesson
        ? seriesLessons[currentIndex - 1]
        : null;

    return Row(
      children: [
        // ── 1. زر الدرس التالي (في أقصى اليمين في واجهة RTL) ───────────────
        Expanded(
          child: Opacity(
            opacity: hasNextLesson ? 1.0 : 0.5,
            child: Material(
              color: AppColors.accentGoldBeige,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: AppColors.accentGoldBeige,
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  if (hasNextLesson && nextLesson != null) {
                    audioProvider.loadAndPlayLesson(
                      lesson: nextLesson,
                      series: currentSeries,
                      book: book,
                      sheikh: sheikh,
                      autoPlay: true,
                    );
                  } else {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'هذا هو الدرس الأخير في هذا الشرح',
                          style: GoogleFonts.readexPro(),
                        ),
                        backgroundColor: AppColors.primaryDarkBrown,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.skip_next_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'الدرس التالي',
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ── 2. زر قائمة الدروس (في المنتصف تماماً) ──────────────────────────
        Expanded(
          child: Material(
            color: AppColors.primaryDarkBrown,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 18,
                        color: AppColors.textGoldLight,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'قائمة الدروس',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGoldLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ── 3. زر الدرس السابق (في أقصى اليسار في واجهة RTL) ────────────────
        Expanded(
          child: Opacity(
            opacity: hasPreviousLesson ? 1.0 : 0.5,
            child: Material(
              color: AppColors.accentGoldBeige,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: AppColors.accentGoldBeige,
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  if (hasPreviousLesson && prevLesson != null) {
                    audioProvider.loadAndPlayLesson(
                      lesson: prevLesson,
                      series: currentSeries,
                      book: book,
                      sheikh: sheikh,
                      autoPlay: true,
                    );
                  } else {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'هذا هو الدرس الأول في هذا الشرح',
                          style: GoogleFonts.readexPro(),
                        ),
                        backgroundColor: AppColors.primaryDarkBrown,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.skip_previous_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'الدرس السابق',
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolCapsule({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accentGoldBeige
                    : AppColors.scaffoldCream,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? AppColors.accentGoldBeige
                      : AppColors.dividerLight,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.textPrimary : AppColors.iconGold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.readexPro(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// نافذة اختيار السرعة
  void _openSpeedBottomSheet(
    BuildContext context,
    AudioProvider audioProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.scaffoldCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'سرعة التشغيل',
                style: GoogleFonts.readexPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: AudioProvider.availableSpeeds.map((spd) {
                  final isSelected = audioProvider.playbackSpeed == spd;
                  return InkWell(
                    onTap: () {
                      audioProvider.setPlaybackSpeed(spd);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryDarkBrown
                            : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryDarkBrown
                              : AppColors.dividerLight,
                        ),
                      ),
                      child: Text(
                        '${spd}x',
                        style: GoogleFonts.readexPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.textWhite
                              : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// نافذة مؤقت النوم
  void _openSleepTimerBottomSheet(
    BuildContext context,
    AudioProvider audioProvider,
  ) {
    final timerOptions = [
      {'label': '15 دقيقة', 'duration': const Duration(minutes: 15)},
      {'label': '30 دقيقة', 'duration': const Duration(minutes: 30)},
      {'label': '45 دقيقة', 'duration': const Duration(minutes: 45)},
      {'label': '60 دقيقة', 'duration': const Duration(minutes: 60)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.scaffoldCream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'مؤقت النوم (إيقاف الصوت تلقائياً)',
                    style: GoogleFonts.readexPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDarkBrown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...timerOptions.map((opt) {
                    final dur = opt['duration'] as Duration;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: AppColors.cardWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.dividerLight),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.timer_outlined,
                            color: AppColors.iconGold,
                          ),
                          title: Text(
                            opt['label'] as String,
                            style: GoogleFonts.readexPro(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.iconGold,
                          ),
                          onTap: () {
                            audioProvider.setSleepTimer(dur);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تم ضبط مؤقت النوم على ${opt["label"]}',
                                  style: GoogleFonts.readexPro(),
                                ),
                                backgroundColor: AppColors.primaryDarkBrown,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                  // خيار "عند انتهاء الدرس الحالي"
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppColors.cardWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: audioProvider.sleepAtEndOfLesson
                              ? AppColors.primaryDarkBrown
                              : AppColors.dividerLight,
                          width: audioProvider.sleepAtEndOfLesson ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.hourglass_bottom_rounded,
                          color: audioProvider.sleepAtEndOfLesson
                              ? AppColors.primaryDarkBrown
                              : AppColors.iconGold,
                        ),
                        title: Text(
                          'عند انتهاء الدرس الحالي',
                          style: GoogleFonts.readexPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: audioProvider.sleepAtEndOfLesson
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primaryDarkBrown,
                              )
                            : const Icon(
                                Icons.chevron_left_rounded,
                                color: AppColors.iconGold,
                              ),
                        onTap: () {
                          audioProvider.setSleepAtEndOfLesson();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'سيتم إيقاف الصوت تلقائياً عند انتهاء هذا الدرس',
                                style: GoogleFonts.readexPro(),
                              ),
                              backgroundColor: AppColors.primaryDarkBrown,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (audioProvider.hasActiveSleepTimer) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          audioProvider.cancelSleepTimer();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم إلغاء مؤقت النوم',
                                style: GoogleFonts.readexPro(),
                              ),
                              backgroundColor: AppColors.primaryDarkBrown,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(
                          'إلغاء المؤقت',
                          style: GoogleFonts.readexPro(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC62828),
                          side: const BorderSide(color: Color(0xFFC62828)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ── بطاقة كناشة الفوائد الخاصة بهذا الدرس ─────────────────────────────────
  Widget _buildLessonNotesCard(
    BuildContext context,
    LessonModel lesson,
    AudioProvider audioProvider,
    AppProvider appProvider,
    BookModel? book,
    SheikhModel? sheikh,
  ) {
    final notes = appProvider.getNotesForLesson(lesson.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط رأس البطاقة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر إضافة فائدة سريع على اليسار في RTL
                OutlinedButton.icon(
                  onPressed: () => _openAddNoteDialog(
                    context,
                    audioProvider,
                    appProvider,
                    lesson,
                    book,
                    sheikh,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    'تدوين فائدة',
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDarkBrown,
                    side: const BorderSide(color: AppColors.accentGoldBeige),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // عنوان القسم وشارة العدد على اليمين في RTL
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (notes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGoldBeige.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${notes.length}',
                          style: GoogleFonts.readexPro(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDarkBrown,
                          ),
                        ),
                      ),
                    Text(
                      'كناشة فوائد الدرس',
                      style: GoogleFonts.readexPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.iconGold,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.dividerLight, height: 1),

          // المحتوى: قائمة الفوائد أو الحالة الفارغة
          Padding(
            padding: const EdgeInsets.all(16),
            child: notes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 36,
                            color: AppColors.textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لم تدوّن أي فائدة لهذا الدرس بعد.',
                            style: GoogleFonts.readexPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اضغط على "تدوين فائدة" لتوثيق فوائدك وفرائدك مرتبطة بالتوقيت الصوتي.',
                            style: GoogleFonts.readexPro(
                              fontSize: 11.5,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: notes.map((note) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldCream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.dividerLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // أزرار الإجراءات (نسخ، تعديل، حذف)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 16),
                                      color: AppColors.iconGold,
                                      tooltip: 'نسخ الفائدة',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        final copyText =
                                            '"${note.content}"\n\n— من درس: ${note.lessonTitle} (عند ${note.formattedTimestamp})\n— شرح: ${note.bookTitle}\n— للشيخ: ${note.sheikhName}\n(تطبيق تسهيل للعلوم الشرعية)';
                                        Clipboard.setData(ClipboardData(text: copyText));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'تم نسخ الفائدة مع مصدرها بنجاح',
                                              style: GoogleFonts.readexPro(),
                                            ),
                                            backgroundColor: AppColors.primaryDarkBrown,
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      color: AppColors.textSecondary,
                                      tooltip: 'تعديل',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _openAddNoteDialog(
                                        context,
                                        audioProvider,
                                        appProvider,
                                        lesson,
                                        book,
                                        sheikh,
                                        note,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                      color: const Color(0xFFC62828),
                                      tooltip: 'حذف',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
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
                                              'هل أنت متأكد من رغبتك في حذف هذه الفائدة؟',
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

                                // شارة التوقيت الزمني القابلة للضغط للانتقال في الصوت
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    audioProvider.seek(Duration(seconds: note.timestampSeconds));
                                    if (!audioProvider.isPlaying) {
                                      audioProvider.play();
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'تم الانتقال إلى الدقيقة ${note.formattedTimestamp}',
                                          style: GoogleFonts.readexPro(),
                                        ),
                                        backgroundColor: AppColors.primaryDarkBrown,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDarkBrown,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 14,
                                          color: AppColors.textGoldLight,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          note.formattedTimestamp,
                                          style: GoogleFonts.readexPro(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textGoldLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              note.content,
                              style: GoogleFonts.readexPro(
                                fontSize: 13,
                                height: 1.6,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  /// نافذة إضافة أو تعديل فائدة
  void _openAddNoteDialog(
    BuildContext context,
    AudioProvider audioProvider,
    AppProvider appProvider,
    LessonModel lesson,
    BookModel? book,
    SheikhModel? sheikh, [
    LessonNoteModel? existingNote,
  ]) {
    final isEditing = existingNote != null;
    final timestampSeconds = isEditing
        ? existingNote.timestampSeconds
        : audioProvider.currentPosition.inSeconds;
    final formattedTime = isEditing
        ? existingNote.formattedTimestamp
        : _formatDuration(audioProvider.currentPosition);
    final textController =
        TextEditingController(text: existingNote?.content ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: AppColors.iconGold,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'تعديل الفائدة' : 'تدوين فائدة علمية',
                style: GoogleFonts.readexPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldCream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.dividerLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.iconGold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'توقيت الفائدة في الدرس: ',
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: GoogleFonts.readexPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                autofocus: true,
                style: GoogleFonts.readexPro(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'اكتب نص الفائدة هنا...',
                  hintStyle: GoogleFonts.readexPro(
                    fontSize: 12.5,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: AppColors.scaffoldCream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.dividerLight),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: GoogleFonts.readexPro(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final text = textController.text.trim();
                if (text.isEmpty) return;

                if (isEditing) {
                  final updated = existingNote.copyWith(content: text);
                  appProvider.updateLessonNote(updated);
                } else {
                  final newNote = LessonNoteModel(
                    id: 'note_${DateTime.now().millisecondsSinceEpoch}',
                    lessonId: lesson.id,
                    lessonTitle: lesson.title,
                    bookTitle: book?.title ?? '',
                    sheikhName: sheikh?.name ?? '',
                    timestampSeconds: timestampSeconds,
                    content: text,
                    createdAt: DateTime.now(),
                  );
                  appProvider.addLessonNote(newNote);
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'تم تحديث الفائدة بنجاح'
                          : 'تم حفظ الفائدة في كناشة الفوائد',
                      style: GoogleFonts.readexPro(),
                    ),
                    backgroundColor: AppColors.primaryDarkBrown,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                isEditing ? 'حفظ التعديل' : 'حفظ الفائدة',
                style: GoogleFonts.readexPro(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    ).whenComplete(() {
      textController.dispose();
    });
  }

  // ─── دوال العلامات المرجعية الصوتية وفواصل الاستماع (Audio Bookmarks) ──────

  Color _parseColorHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFD4AF37);
    }
  }

  /// شريط فواصل الاستماع أسفل شريط التقدم مباشرة
  Widget _buildAudioBookmarksRow(
    BuildContext context,
    AudioProvider audioProvider,
    AppProvider appProvider,
    LessonModel lesson,
  ) {
    final bookmarks = appProvider.getAudioBookmarksForLesson(lesson.id);
    if (bookmarks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4, right: 6, left: 6),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: bookmarks.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final bm = bookmarks[index];
            final color = _parseColorHex(bm.colorHex);

            return InkWell(
              onTap: () {
                audioProvider.seek(Duration(seconds: bm.positionSeconds));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'انتقل المشغل إلى فاصل ${bm.formattedTimestamp}${bm.label != null && bm.label!.isNotEmpty ? ' (${bm.label})' : ''}',
                      style: GoogleFonts.readexPro(),
                    ),
                    backgroundColor: AppColors.primaryDarkBrown,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              onLongPress: () =>
                  _confirmDeleteBookmark(context, appProvider, bm),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      bm.formattedTimestamp,
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (bm.label != null && bm.label!.trim().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          bm.label!,
                          style: GoogleFonts.readexPro(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () =>
                          _confirmDeleteBookmark(context, appProvider, bm),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// نافذة إضافة فاصل استماع جديد
  void _openAddBookmarkDialog(
    BuildContext context,
    AudioProvider audioProvider,
    AppProvider appProvider,
    LessonModel lesson,
  ) {
    final curPos = audioProvider.currentPosition;
    final posSec = curPos.inSeconds;
    final formattedTime = _formatDuration(curPos);
    final labelController = TextEditingController();

    const scholarColors = [
      {'name': 'ذهبي', 'hex': '#D4AF37', 'color': Color(0xFFD4AF37)},
      {'name': 'أخضر زمردي', 'hex': '#2E7D32', 'color': Color(0xFF2E7D32)},
      {'name': 'أزرق سماوي', 'hex': '#0288D1', 'color': Color(0xFF0288D1)},
      {'name': 'أحمر ياقوتي', 'hex': '#C62828', 'color': Color(0xFFC62828)},
    ];

    String selectedColorHex = '#D4AF37';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardWhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(
                Icons.bookmark_add_rounded,
                color: AppColors.primaryDarkBrown,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'إضافة فاصل سماع',
                style: GoogleFonts.readexPro(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // شارة الوقت الحالي
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldBeige.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentGoldBeige.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: AppColors.primaryDarkBrown,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'عند الدقيقة: $formattedTime',
                        style: GoogleFonts.readexPro(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDarkBrown,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // حقل التسمية الاختياري
                TextField(
                  controller: labelController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'عنوان أو وصف للفاصل (اختياري)',
                    hintText: 'مثال: مسألة مهمة، تفريع أصولي...',
                    labelStyle: GoogleFonts.readexPro(fontSize: 12),
                    hintStyle: GoogleFonts.readexPro(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // اختيار اللون العلمي المميز
                Text(
                  'لون شارة الفاصل:',
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: scholarColors.map((c) {
                    final isSelected = selectedColorHex == c['hex'];
                    final color = c['color'] as Color;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedColorHex = c['hex'] as String;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryDarkBrown
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: GoogleFonts.readexPro(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final bookmark = AudioBookmarkModel(
                  id: 'bm_${DateTime.now().millisecondsSinceEpoch}',
                  lessonId: lesson.id,
                  positionSeconds: posSec,
                  label: labelController.text.trim().isNotEmpty
                      ? labelController.text.trim()
                      : null,
                  colorHex: selectedColorHex,
                  createdAt: DateTime.now(),
                );
                await appProvider.addAudioBookmark(bookmark);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم حفظ فاصل السماع عند $formattedTime بنجاح',
                        style: GoogleFonts.readexPro(),
                      ),
                      backgroundColor: AppColors.primaryDarkBrown,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
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
                'حفظ الفاصل',
                style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      labelController.dispose();
    });
  }

  /// نافذة تأكيد حذف فاصل سماع
  void _confirmDeleteBookmark(
    BuildContext context,
    AppProvider appProvider,
    AudioBookmarkModel bookmark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'حذف فاصل السماع؟',
          style: GoogleFonts.readexPro(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDarkBrown,
          ),
        ),
        content: Text(
          'هل تريد حذف فاصل السماع عند ${bookmark.formattedTimestamp}${bookmark.label != null && bookmark.label!.isNotEmpty ? ' (${bookmark.label})' : ''}؟',
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
              await appProvider.deleteAudioBookmark(bookmark.id);
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

  /// ── 3. قسم التفريغ النصي أسفل المشغل ──────────────────────────────────
  Widget _buildTranscriptCard(
    BuildContext context,
    LessonModel lesson,
    BookModel? book,
    SheikhModel? sheikh,
    AppProvider appProvider,
  ) {
    final hasTranscript = lesson.hasTranscript;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط عنوان التفريغ وأزرار الأدوات
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // أدوات التكبير والتصغير والبحث وشارة التظليلات
                if (hasTranscript)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMiniTextButton('A+', () {
                        setState(() {
                          if (_transcriptFontSize < 26.0) {
                            _transcriptFontSize += 2.0;
                          }
                        });
                      }),
                      const SizedBox(width: 6),
                      _buildMiniTextButton('A-', () {
                        setState(() {
                          if (_transcriptFontSize > 13.0) {
                            _transcriptFontSize -= 2.0;
                          }
                        });
                      }),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'بحث في التفريغ',
                        icon: Icon(
                          _isSearchVisible
                              ? Icons.search_off_rounded
                              : Icons.search_rounded,
                          size: 20,
                          color: _isSearchVisible
                              ? AppColors.primaryDarkBrown
                              : AppColors.iconGold,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchVisible = !_isSearchVisible;
                            if (!_isSearchVisible) {
                              _searchQuery = '';
                              _searchController.clear();
                            }
                          });
                        },
                      ),
                      Builder(
                        builder: (_) {
                          final highlights =
                              appProvider.getHighlightsForLesson(lesson.id);
                          if (highlights.isEmpty) return const SizedBox.shrink();
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 4),
                              _buildMiniHighlightsBadge(
                                highlights.length,
                                () => _showHighlightsSheet(
                                  context,
                                  appProvider,
                                  lesson,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),

                // عنوان القسم
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تفريغ الدرس',
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.description_rounded,
                      color: AppColors.iconGold,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // حقل البحث في التفريغ (إن فُعّل)
          if (hasTranscript && _isSearchVisible) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن كلمة في نص الدرس...',
                  isDense: true,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.iconGold,
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
                ),
              ),
            ),
          ],

          const Divider(color: AppColors.dividerLight, height: 1),

          // ── محتوى التفريغ (حالة التوفر أو الاعتذار) ───────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: hasTranscript
                ? _buildTranscriptContent(context, lesson, appProvider)
                : _buildMissingTranscriptState(context, lesson, book, sheikh),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTextButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.scaffoldCream,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: Text(
          text,
          style: GoogleFonts.readexPro(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// شارة إحصائية لعدد التظليلات في التفريغ
  Widget _buildMiniHighlightsBadge(int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF59D).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.iconGold),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.format_color_fill_rounded,
              size: 14,
              color: AppColors.primaryDarkBrown,
            ),
            const SizedBox(width: 4),
            Text(
              '$count تظليل',
              style: GoogleFonts.readexPro(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// الحالة الأولى: عرض نص التفريغ مع دعم التحديد المتقدم والتظليلات العلمية الثلاثية
  Widget _buildTranscriptContent(
    BuildContext context,
    LessonModel lesson,
    AppProvider appProvider,
  ) {
    final fullText = lesson.transcript;
    final highlights = appProvider.getHighlightsForLesson(lesson.id);

    return SelectableText.rich(
      TextSpan(
        style: GoogleFonts.amiri(
          fontSize: _transcriptFontSize,
          height: 2.1,
          color: AppColors.textPrimary,
        ),
        children: _buildHighlightedSpans(
          context: context,
          fullText: fullText,
          highlights: highlights,
          searchQuery: _searchQuery,
          lessonId: lesson.id,
          appProvider: appProvider,
        ),
      ),
      textAlign: TextAlign.justify,
      contextMenuBuilder: (BuildContext ctx, EditableTextState editableTextState) {
        final selection = editableTextState.textEditingValue.selection;
        final hasValidSelection = !selection.isCollapsed &&
            selection.start >= 0 &&
            selection.end <= fullText.length &&
            selection.start < selection.end;

        final List<ContextMenuButtonItem> items =
            List.from(editableTextState.contextMenuButtonItems);

        if (hasValidSelection) {
          // إضافة خيارات الألوان العلمية الثلاثة في بداية القائمة المنبثقة
          items.insert(
            0,
            ContextMenuButtonItem(
              label: '🟡 أصفر',
              onPressed: () {
                editableTextState.hideToolbar();
                _saveHighlight(
                  lessonId: lesson.id,
                  fullText: fullText,
                  start: selection.start,
                  end: selection.end,
                  colorHex: '#FFF59D',
                  appProvider: appProvider,
                );
              },
            ),
          );
          items.insert(
            1,
            ContextMenuButtonItem(
              label: '🟢 أخضر',
              onPressed: () {
                editableTextState.hideToolbar();
                _saveHighlight(
                  lessonId: lesson.id,
                  fullText: fullText,
                  start: selection.start,
                  end: selection.end,
                  colorHex: '#C8E6C9',
                  appProvider: appProvider,
                );
              },
            ),
          );
          items.insert(
            2,
            ContextMenuButtonItem(
              label: '🟠 ذهبي',
              onPressed: () {
                editableTextState.hideToolbar();
                _saveHighlight(
                  lessonId: lesson.id,
                  fullText: fullText,
                  start: selection.start,
                  end: selection.end,
                  colorHex: '#FFE082',
                  appProvider: appProvider,
                );
              },
            ),
          );
        }

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: items,
        );
      },
    );
  }

  /// حفظ تظليل جديد في مزود الحالة
  void _saveHighlight({
    required String lessonId,
    required String fullText,
    required int start,
    required int end,
    required String colorHex,
    required AppProvider appProvider,
  }) {
    final text = fullText.substring(start, end).trim();
    if (text.isEmpty) return;

    final highlight = TranscriptHighlightModel(
      id: 'hl_${DateTime.now().millisecondsSinceEpoch}',
      lessonId: lessonId,
      selectedText: text,
      startIndex: start,
      endIndex: end,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );

    appProvider.addTranscriptHighlight(highlight);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تظليل العبارة بنجاح وحفظها', style: GoogleFonts.readexPro()),
        backgroundColor: AppColors.primaryDarkBrown,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// تحويل كود اللون الست عشري إلى كائن Color
  Color _parseHighlightColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').replaceAll('0x', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFFFF59D);
  }

  /// تقسيم النص إلى فترات تجمع بين التظليلات المحفوظة ونتائج البحث
  List<InlineSpan> _buildHighlightedSpans({
    required BuildContext context,
    required String fullText,
    required List<TranscriptHighlightModel> highlights,
    required String searchQuery,
    required String lessonId,
    required AppProvider appProvider,
  }) {
    if (fullText.isEmpty) return const [];

    // ترتيب التظليلات وضمان سلامة النطاقات
    final validHighlights = highlights
        .where((h) =>
            h.startIndex >= 0 &&
            h.endIndex <= fullText.length &&
            h.startIndex < h.endIndex)
        .toList()
      ..sort((a, b) => a.startIndex.compareTo(b.startIndex));

    // دمج أو تجنب تداخل النطاقات
    final nonOverlapping = <TranscriptHighlightModel>[];
    int lastCovered = 0;
    for (final h in validHighlights) {
      if (h.startIndex >= lastCovered) {
        nonOverlapping.add(h);
        lastCovered = h.endIndex;
      } else if (h.endIndex > lastCovered) {
        nonOverlapping.add(h.copyWith(startIndex: lastCovered));
        lastCovered = h.endIndex;
      }
    }

    final spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final h in nonOverlapping) {
      // 1. النص غير المظلل قبل هذا التظليل
      if (h.startIndex > currentIndex) {
        final unhighlighted = fullText.substring(currentIndex, h.startIndex);
        spans.addAll(_buildSearchSubSpans(unhighlighted, searchQuery, null));
      }

      // 2. النص المظلل
      final highlightedText = fullText.substring(h.startIndex, h.endIndex);
      final color = _parseHighlightColor(h.colorHex);

      spans.add(
        TextSpan(
          text: highlightedText,
          style: TextStyle(
            backgroundColor: color,
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _showHighlightOptionsDialog(context, appProvider, lessonId, h);
            },
        ),
      );

      currentIndex = h.endIndex;
    }

    // 3. ما تبقى من النص بعد آخر تظليل
    if (currentIndex < fullText.length) {
      final remaining = fullText.substring(currentIndex);
      spans.addAll(_buildSearchSubSpans(remaining, searchQuery, null));
    }

    return spans;
  }

  /// تقسيم المقطع الجزئي وفق كلمة البحث إن وجدت
  List<InlineSpan> _buildSearchSubSpans(
    String text,
    String searchQuery,
    Color? baseBgColor,
  ) {
    if (searchQuery.isEmpty) {
      return [
        TextSpan(
          text: text,
          style: baseBgColor != null ? TextStyle(backgroundColor: baseBgColor) : null,
        ),
      ];
    }

    final spans = <InlineSpan>[];
    final query = searchQuery.toLowerCase();
    final lowerText = text.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(query, start);
      if (index == -1) {
        spans.add(
          TextSpan(
            text: text.substring(start),
            style: baseBgColor != null ? TextStyle(backgroundColor: baseBgColor) : null,
          ),
        );
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: baseBgColor != null ? TextStyle(backgroundColor: baseBgColor) : null,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return spans;
  }

  /// نافذة منبثقة عند الضغط على عبارة مظللة (نسخ أو إزالة التظليل)
  void _showHighlightOptionsDialog(
    BuildContext context,
    AppProvider appProvider,
    String lessonId,
    TranscriptHighlightModel highlight,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.scaffoldCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _parseHighlightColor(highlight.colorHex),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryDarkBrown, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'خيارات العبارة المظللة',
                      style: GoogleFonts.readexPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dividerLight),
                  ),
                  child: Text(
                    highlight.selectedText,
                    style: GoogleFonts.amiri(
                      fontSize: 16,
                      height: 1.8,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text('نسخ العبارة', style: GoogleFonts.readexPro(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDarkBrown,
                          side: const BorderSide(color: AppColors.primaryDarkBrown),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: highlight.selectedText));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم نسخ العبارة للحافظة', style: GoogleFonts.readexPro()),
                              backgroundColor: AppColors.primaryDarkBrown,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.format_color_reset_rounded, size: 18),
                        label: Text(
                          'إزالة التظليل',
                          style: GoogleFonts.readexPro(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await appProvider.removeTranscriptHighlight(lessonId, highlight.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تمت إزالة التظليل بنجاح', style: GoogleFonts.readexPro()),
                                backgroundColor: AppColors.primaryDarkBrown,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// نافذة عرض وإدارة كافة تظليلات الدرس الحالي
  void _showHighlightsSheet(
    BuildContext context,
    AppProvider appProvider,
    LessonModel lesson,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.scaffoldCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<AppProvider>(
          builder: (context, ap, _) {
            final list = ap.getHighlightsForLesson(lesson.id);

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.format_color_fill_rounded,
                              color: AppColors.iconGold,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'تظليلات هذا الدرس (${list.length})',
                              style: GoogleFonts.readexPro(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDarkBrown,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.dividerLight),
                    const SizedBox(height: 8),
                    if (list.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'لم تقم بتظليل أي عبارة في هذا الدرس بعد.',
                            style: GoogleFonts.readexPro(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final h = list[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.dividerLight),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: _parseHighlightColor(h.colorHex),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      h.selectedText,
                                      style: GoogleFonts.amiri(
                                        fontSize: 15,
                                        height: 1.8,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 18),
                                    tooltip: 'نسخ',
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: h.selectedText));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تم نسخ العبارة', style: GoogleFonts.readexPro()),
                                          backgroundColor: AppColors.primaryDarkBrown,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                    tooltip: 'حذف التظليل',
                                    onPressed: () async {
                                      await ap.removeTranscriptHighlight(lesson.id, h.id);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// الحالة الثانية: عند عدم توفر التفريغ النصي مع زر واتساب
  Widget _buildMissingTranscriptState(
    BuildContext context,
    LessonModel lesson,
    BookModel? book,
    SheikhModel? sheikh,
  ) {
    final bookTitle = book?.title ?? 'المتن';
    final sheikhName = sheikh?.name ?? 'الشيخ';

    final whatsappMessage =
        'السلام عليكم ورحمة الله، أراسلكم من تطبيق تسهيل للعلوم الشرعية، وأود المساهمة في تفريغ (${lesson.title}) من شرح ($bookTitle) للشيخ ($sheikhName).';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.scaffoldCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accentGoldBeige.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.iconGold,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),

          // النص المطلوب بدقة
          Text(
            'لم يتم تفريغ الدرس بعد، إن أحببت المساعدة في ذلك راسلنا من زر الدعم الفني في القائمة الجانبية، أول اضغط على الزر أدناه',
            style: GoogleFonts.readexPro(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 18),

          // زر المساهمة عبر واتساب
          ElevatedButton.icon(
            onPressed: () async {
              final appProvider = Provider.of<AppProvider>(
                context,
                listen: false,
              );
              final rawPhone = appProvider.aboutApp.supportWhatsapp;
              final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
              final encoded = Uri.encodeComponent(whatsappMessage);
              final waUri = cleanPhone.isNotEmpty
                  ? Uri.parse('https://wa.me/$cleanPhone?text=$encoded')
                  : Uri.parse('https://wa.me/?text=$encoded');
              try {
                if (await canLaunchUrl(waUri)) {
                  await launchUrl(waUri, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(waUri);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تعذر فتح واتساب تلقائياً، يمكنك مراسلتنا من شاشة المزيد.',
                        style: GoogleFonts.readexPro(),
                      ),
                      backgroundColor: AppColors.primaryDarkBrown,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            label: Text(
              'راسلنا (عبر واتساب) للمساهمة',
              style: GoogleFonts.readexPro(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ─── دوال مساعدة لحساب الوقت ─────────────────────────────────────────────
  String _formatDuration(Duration dur) {
    final minutes = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (dur.inHours > 0) {
      final hours = dur.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Duration _parseDurationString(String str) {
    try {
      final parts = str.split(':');
      if (parts.length == 2) {
        return Duration(
          minutes: int.parse(parts[0]),
          seconds: int.parse(parts[1]),
        );
      } else if (parts.length == 3) {
        return Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
          seconds: int.parse(parts[2]),
        );
      }
    } catch (_) {}
    return Duration.zero;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة قراءة الـ PDF بملء الشاشة مع شريط التحكم الصوتي العائم
/// ═══════════════════════════════════════════════════════════════════════════
class FullScreenPdfScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const FullScreenPdfScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDarkBrown,
        foregroundColor: AppColors.textGoldLight,
        title: Text(
          title,
          style: GoogleFonts.readexPro(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_fullscreen_rounded),
            onPressed: () => Navigator.pop(context),
            tooltip: 'إغلاق ملء الشاشة',
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            pdfUrl,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
          ),
          // كبسولة عائمة في الأسفل للتحكم بالصوت
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(30),
              color: AppColors.primaryDarkBrown.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.replay_5_rounded,
                        color: AppColors.textGoldLight,
                      ),
                      onPressed: () => audioProvider.seekBackward5s(),
                    ),
                    IconButton(
                      icon: Icon(
                        audioProvider.isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        color: AppColors.textGoldLight,
                        size: 34,
                      ),
                      onPressed: () => audioProvider.togglePlayPause(),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.forward_5_rounded,
                        color: AppColors.textGoldLight,
                      ),
                      onPressed: () => audioProvider.seekForward5s(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatDuration(audioProvider.currentPosition)} / ${_formatDuration(audioProvider.totalDuration)}',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (audioProvider.isLoopActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGoldBeige,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'A-B نشط',
                          style: GoogleFonts.readexPro(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkBrown,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration dur) {
    final minutes = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = dur.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

