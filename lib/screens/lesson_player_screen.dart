import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../core/theme/app_colors.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../providers/audio_provider.dart';
import '../services/mock_data_service.dart';
import '../widgets/decorated_header.dart';

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

  const LessonPlayerScreen({
    super.key,
    required this.lesson,
    required this.series,
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

  /// تبديل وضع الوسائط بين الاستماع الصوتي ومشاهدة الفيديو
  void _onMediaModeChanged(int newMode, LessonModel currentLesson) {
    if (_selectedMediaMode == newMode) return;

    if (newMode == 1) {
      // 1. إيقاف المشغل الصوتي مؤقتاً فور التبديل لوضع الفيديو حتى لا يتداخل الصوتين
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      if (audioProvider.isPlaying) {
        audioProvider.pause();
      }

      // 2. تهيئة مشغل يوتيوب الداخلي
      final videoId = extractYoutubeVideoId(currentLesson.videoUrl);
      if (videoId != null) {
        _initYoutubeController(videoId);
      }
    } else {
      // 3. تفريغ وإغلاق مشغل الفيديو عند العودة إلى وضع "الاستماع الصوتي"
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
    final baseLesson = (audioProvider.currentSeries?.id == widget.series.id &&
            audioProvider.currentLesson != null)
        ? audioProvider.currentLesson!
        : widget.lesson;
    final currentLesson = appProvider.getLessonById(baseLesson.id) ?? baseLesson;

    final currentSeries = appProvider.getSeriesById(widget.series.id) ?? widget.series;
    final book = appProvider.getBookById(currentSeries.bookId) ??
        MockDataService.getBookById(currentSeries.bookId);
    final sheikh = appProvider.getSheikhById(currentSeries.sheikhId) ??
        MockDataService.getSheikhById(currentSeries.sheikhId);
    final hasVideo = currentLesson.hasVideo;

    // إذا تم الانتقال لدرس لا يحتوي على فيديو، العودة التلقائية لوضع الصوت
    if (!hasVideo && _selectedMediaMode == 1) {
      _selectedMediaMode = 0;
      _disposeYoutubeController();
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      body: Column(
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
                  // ── كبسولة التبديل (صوت / فيديو يوتيوب) إن توفر الفيديو ───
                  if (hasVideo) ...[
                    _buildMediaToggleCapsule(currentLesson),
                    const SizedBox(height: 14),
                  ],

                  // ── عرض بطاقة الفيديو أو بطاقة المشغل الصوتي ─────────────
                  if (_selectedMediaMode == 1 && hasVideo)
                    _buildYouTubeCard(currentLesson, book, sheikh)
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

                  // ── قسم التفريغ النصي أسفل المشغل ───────────────────────
                  _buildTranscriptCard(context, currentLesson, book, sheikh),
                ],
              ),
            ),
          ),
        ],
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

  /// كبسولة التبديل بين الاستماع الصوتي وفيديو يوتيوب
  Widget _buildMediaToggleCapsule(LessonModel currentLesson) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.dividerLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleItem(
              title: 'استماع صوتي',
              icon: Icons.headphones_rounded,
              isSelected: _selectedMediaMode == 0,
              onTap: () => _onMediaModeChanged(0, currentLesson),
            ),
            _buildToggleItem(
              title: 'مشاهدة فيديو',
              icon: Icons.ondemand_video_rounded,
              isSelected: _selectedMediaMode == 1,
              onTap: () => _onMediaModeChanged(1, currentLesson),
            ),
          ],
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
              color: isSelected ? AppColors.textGoldLight : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.readexPro(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة فيديو يوتيوب المدمجة مع زر الانتقال الخارجي
  Widget _buildYouTubeCard(LessonModel lesson, BookModel? book, SheikhModel? sheikh) {
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
              border: Border.all(
                color: AppColors.accentGoldBeige,
                width: 1.5,
              ),
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
                                videoId != null
                                    ? 'جاري تجهيز مشغل الفيديو...'
                                    : 'يتوفر تسجيل لهذا الدرس، يمكنك فتحه عبر الزر أدناه',
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
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
    final curMs = currentPos.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);

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
                  _formatDuration(totalDur.inSeconds > 0 ? totalDur : _parseDurationString(lesson.duration)),
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                        color: AppColors.primaryDarkBrown.withValues(alpha: 0.35),
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
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textGoldLight),
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

          const SizedBox(height: 20),
          const Divider(color: AppColors.dividerLight, height: 1),
          const SizedBox(height: 14),

          // ── شريط الأدوات الإضافية (4 كبسولات) ────────────────────
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
                    ? _formatDuration(audioProvider.remainingSleepTime!)
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
    final seriesLessons = appProvider.getLessonsBySeries(currentSeries.id).isNotEmpty
        ? appProvider.getLessonsBySeries(currentSeries.id)
        : MockDataService.getLessonsBySeries(currentSeries.id);

    int currentIndex = seriesLessons.indexWhere((l) => l.id == currentLesson.id);
    if (currentIndex == -1) {
      currentIndex = seriesLessons.indexWhere((l) => l.order == currentLesson.order);
    }

    final hasNextLesson = currentIndex != -1 && currentIndex < seriesLessons.length - 1;
    final nextLesson = hasNextLesson ? seriesLessons[currentIndex + 1] : null;

    final hasPreviousLesson = currentIndex > 0;
    final prevLesson = hasPreviousLesson ? seriesLessons[currentIndex - 1] : null;

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
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// نافذة اختيار السرعة
  void _openSpeedBottomSheet(BuildContext context, AudioProvider audioProvider) {
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
                        color: isSelected ? AppColors.primaryDarkBrown : AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryDarkBrown : AppColors.dividerLight,
                        ),
                      ),
                      child: Text(
                        '${spd}x',
                        style: GoogleFonts.readexPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
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
  void _openSleepTimerBottomSheet(BuildContext context, AudioProvider audioProvider) {
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
                          leading: const Icon(Icons.timer_outlined, color: AppColors.iconGold),
                          title: Text(
                            opt['label'] as String,
                            style: GoogleFonts.readexPro(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.iconGold),
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
                  if (audioProvider.hasActiveSleepTimer) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          audioProvider.cancelSleepTimer();
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC62828),
                          side: const BorderSide(color: Color(0xFFC62828)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'إيقاف المؤقت النشط',
                          style: GoogleFonts.readexPro(fontSize: 13, fontWeight: FontWeight.w600),
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

  /// ── 3. قسم التفريغ النصي أسفل المشغل ──────────────────────────────────
  Widget _buildTranscriptCard(
    BuildContext context,
    LessonModel lesson,
    BookModel? book,
    SheikhModel? sheikh,
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
                // أدوات التكبير والتصغير والبحث (تظهر فقط عند توفر التفريغ)
                if (hasTranscript)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMiniTextButton('A+', () {
                        setState(() {
                          if (_transcriptFontSize < 26.0) _transcriptFontSize += 2.0;
                        });
                      }),
                      const SizedBox(width: 6),
                      _buildMiniTextButton('A-', () {
                        setState(() {
                          if (_transcriptFontSize > 13.0) _transcriptFontSize -= 2.0;
                        });
                      }),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'بحث في التفريغ',
                        icon: Icon(
                          _isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded,
                          size: 20,
                          color: _isSearchVisible ? AppColors.primaryDarkBrown : AppColors.iconGold,
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
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.iconGold),
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
                ? _buildTranscriptContent(lesson.transcript)
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

  /// الحالة الأولى: عرض نص التفريغ مع تظليل البحث
  Widget _buildTranscriptContent(String fullText) {
    if (_searchQuery.isEmpty) {
      return Text(
        fullText,
        style: GoogleFonts.amiri(
          fontSize: _transcriptFontSize,
          height: 2.1,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.justify,
      );
    }

    // تظليل نتائج البحث
    final spans = <TextSpan>[];
    final query = _searchQuery.toLowerCase();
    int start = 0;

    final lowerText = fullText.toLowerCase();
    while (true) {
      final index = lowerText.indexOf(query, start);
      if (index == -1) {
        spans.add(TextSpan(text: fullText.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: fullText.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: fullText.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFE082),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(
        style: GoogleFonts.amiri(
          fontSize: _transcriptFontSize,
          height: 2.1,
          color: AppColors.textPrimary,
        ),
        children: spans,
      ),
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
            'لم يتم تفريغ الدرس بعد، إن أحببت المساعدة في ذلك راسلنا من زر الدعم الفني في القائمة الجانبية',
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
              final appProvider = Provider.of<AppProvider>(context, listen: false);
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
              'ساهم في تفريغ الدرس (عبر واتساب)',
              style: GoogleFonts.readexPro(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        return Duration(minutes: int.parse(parts[0]), seconds: int.parse(parts[1]));
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
