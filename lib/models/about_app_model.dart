// ═══════════════════════════════════════════════════════════════════════════
// نماذج بيانات صفحة عن التطبيق والمشاريع وإعدادات التواصل والمشاركة
// ═══════════════════════════════════════════════════════════════════════════

/// نموذج المشروع في قسم "من مشاريعنا التقنية والعلمية"
class OurProjectModel {
  final String id;
  final String title;
  final String description;
  final String url;

  const OurProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
    };
  }

  factory OurProjectModel.fromMap(Map<String, dynamic> map) {
    return OurProjectModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
    );
  }

  OurProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? url,
  }) {
    return OurProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
    );
  }
}

/// نموذج إعدادات صفحة عن التطبيق، قنوات التواصل، الدعم الفني، والمشاركة
class AboutAppModel {
  final String appDescription;
  final String telegramUrl;
  final String facebookUrl;
  final String youtubeUrl;
  final String websiteUrl;
  final String supportWhatsapp;
  final String shareDescription;
  final String shareUrl;
  final List<OurProjectModel> projects;

  const AboutAppModel({
    required this.appDescription,
    required this.telegramUrl,
    required this.facebookUrl,
    required this.youtubeUrl,
    required this.websiteUrl,
    required this.supportWhatsapp,
    required this.shareDescription,
    required this.shareUrl,
    required this.projects,
  });

  /// القيم الافتراضية الأولية المطابقة لهوية التطبيق
  factory AboutAppModel.defaultData() {
    return const AboutAppModel(
      appDescription:
          'تطبيق "تسهيل" هو بوابتك الموثوقة لتيسير طلب العلوم الشرعية والتأصيل العلمي الرصين. '
          'يهدف التطبيق إلى تقريب شروحات المتون التأصيلية لكبار أئمة السنة وعلمائها المعاصرين، '
          'مع إتاحة التفريغات النصية المدققة والاستماع المباشر وبدون اتصال بالإنترنت، '
          'خدمةً لطلاب العلم والباحثين في شتى بقاع الأرض.',
      telegramUrl: 'https://t.me/tasheel_app',
      facebookUrl: 'https://facebook.com/tasheel.app',
      youtubeUrl: 'https://youtube.com/@tasheel_app',
      websiteUrl: 'https://madoverse.site/tasheel',
      supportWhatsapp: '213555000000',
      shareDescription:
          'تطبيق (تسهيل) طريقك لتيسير العلوم الشرعية.. استمع لشروحات المتون العلمية لكبار العلماء مع التفريغات النصية وميزة الاستماع بدون إنترنت. حمله الآن:',
      shareUrl: 'https://madoverse.site/tasheel',
      projects: [
        OurProjectModel(
          id: 'proj_1',
          title: 'منصة متون العلمية',
          description:
              'بوابة إلكترونية متخصصة في حفظ ومراجعة متون طالب العلم وفق مستويات منهجية متدرجة.',
          url: 'https://madoverse.site/mutoon',
        ),
        OurProjectModel(
          id: 'proj_2',
          title: 'جامع الفتاوى والتأصيل',
          description:
              'محرك بحث متقدم لفتاوى كبار العلماء وأئمة السلف مع تصنيف فقهي ميسر وموثوق.',
          url: 'https://madoverse.site/fatawa',
        ),
        OurProjectModel(
          id: 'proj_3',
          title: 'المقرأة التيسيرية القرآنية',
          description:
              'حلقات إلكترونية لتصحيح التلاوة وإتقان التجويد والإجازة بالسند المتصل عن بعد.',
          url: 'https://madoverse.site/quran',
        ),
      ],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appDescription': appDescription,
      'telegramUrl': telegramUrl,
      'facebookUrl': facebookUrl,
      'youtubeUrl': youtubeUrl,
      'websiteUrl': websiteUrl,
      'supportWhatsapp': supportWhatsapp,
      'shareDescription': shareDescription,
      'shareUrl': shareUrl,
      'projects': projects.map((p) => p.toMap()).toList(),
    };
  }

  factory AboutAppModel.fromMap(Map<String, dynamic> map) {
    final defaultModel = AboutAppModel.defaultData();
    var projectList = defaultModel.projects;
    if (map['projects'] is List) {
      projectList = (map['projects'] as List)
          .map((item) => OurProjectModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return AboutAppModel(
      appDescription: map['appDescription']?.toString() ?? defaultModel.appDescription,
      telegramUrl: map['telegramUrl']?.toString() ?? defaultModel.telegramUrl,
      facebookUrl: map['facebookUrl']?.toString() ?? defaultModel.facebookUrl,
      youtubeUrl: map['youtubeUrl']?.toString() ?? defaultModel.youtubeUrl,
      websiteUrl: map['websiteUrl']?.toString() ?? defaultModel.websiteUrl,
      supportWhatsapp: map['supportWhatsapp']?.toString() ?? defaultModel.supportWhatsapp,
      shareDescription: map['shareDescription']?.toString() ?? defaultModel.shareDescription,
      shareUrl: map['shareUrl']?.toString() ?? defaultModel.shareUrl,
      projects: projectList,
    );
  }

  AboutAppModel copyWith({
    String? appDescription,
    String? telegramUrl,
    String? facebookUrl,
    String? youtubeUrl,
    String? websiteUrl,
    String? supportWhatsapp,
    String? shareDescription,
    String? shareUrl,
    List<OurProjectModel>? projects,
  }) {
    return AboutAppModel(
      appDescription: appDescription ?? this.appDescription,
      telegramUrl: telegramUrl ?? this.telegramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      supportWhatsapp: supportWhatsapp ?? this.supportWhatsapp,
      shareDescription: shareDescription ?? this.shareDescription,
      shareUrl: shareUrl ?? this.shareUrl,
      projects: projects ?? this.projects,
    );
  }
}
