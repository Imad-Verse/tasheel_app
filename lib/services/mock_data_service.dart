import '../models/models.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// خدمة البيانات التجريبية
/// ═══════════════════════════════════════════════════════════════════════════
/// توفر بيانات واقعية باللغة العربية لاختبار التطبيق.
/// سيتم استبدالها بـ Firebase Firestore في المراحل اللاحقة.
/// ═══════════════════════════════════════════════════════════════════════════
class MockDataService {
  MockDataService._();

  // ═══════════════════════════════════════════════════════════════════════════
  //  الأقسام العلمية
  // ═══════════════════════════════════════════════════════════════════════════

  static final List<CategoryModel> categories = [
    const CategoryModel(
      id: 'cat_aqeedah',
      name: 'العقيدة',
      iconName: 'star',
      booksCount: 3,
      sheikhsCount: 4,
      lessonsCount: 45,
    ),
    const CategoryModel(
      id: 'cat_fiqh',
      name: 'الفقه',
      iconName: 'balance',
      booksCount: 2,
      sheikhsCount: 3,
      lessonsCount: 38,
    ),
    const CategoryModel(
      id: 'cat_usool_fiqh',
      name: 'أصول الفقه',
      iconName: 'foundation',
      booksCount: 1,
      sheikhsCount: 2,
      lessonsCount: 20,
    ),
    const CategoryModel(
      id: 'cat_hadith',
      name: 'الحديث',
      iconName: 'scroll',
      booksCount: 1,
      sheikhsCount: 3,
      lessonsCount: 30,
    ),
    const CategoryModel(
      id: 'cat_faraid',
      name: 'الفرائض',
      iconName: 'pie_chart',
      booksCount: 1,
      sheikhsCount: 2,
      lessonsCount: 15,
    ),
    const CategoryModel(
      id: 'cat_arabic',
      name: 'اللغة العربية',
      iconName: 'language',
      booksCount: 1,
      sheikhsCount: 2,
      lessonsCount: 22,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  //  الشيوخ والعلماء
  // ═══════════════════════════════════════════════════════════════════════════

  static final List<SheikhModel> sheikhs = [
    const SheikhModel(
      id: 'sheikh_uthaymeen',
      name: 'الشيخ محمد بن صالح العثيمين',
      shortBio:
          'عالم وفقيه سعودي، من كبار علماء المملكة العربية السعودية في القرن العشرين.',
      fullBio:
          'هو أبو عبد الله محمد بن صالح بن محمد بن سليمان بن عبد الرحمن العثيمين الوهيبي التميمي. '
          'ولد في ليلة السابع والعشرين من شهر رمضان المبارك عام 1347هـ في مدينة عنيزة بمنطقة القصيم. '
          'تعلم القرآن الكريم على يد جده من جهة أمه عبد الرحمن بن سليمان آل دامغ، ثم تعلم الكتابة وشيئاً '
          'من الأدب والحساب والتحق بمدرسة تعليم القرآن الكريم. درس على يد الشيخ عبد الرحمن بن ناصر السعدي '
          'والشيخ عبد العزيز بن باز رحمهما الله. ترك إرثاً علمياً ضخماً من المؤلفات والشروحات والفتاوى '
          'التي لا تزال مرجعاً أساسياً لطلاب العلم في شتى أنحاء العالم الإسلامي. '
          'توفي رحمه الله في الخامس عشر من شهر شوال عام 1421هـ.',
      booksCount: 3,
      lessonsCount: 55,
    ),
    const SheikhModel(
      id: 'sheikh_bin_baz',
      name: 'الشيخ عبد العزيز بن باز',
      shortBio:
          'المفتي العام للمملكة العربية السعودية سابقاً، ورئيس هيئة كبار العلماء.',
      fullBio:
          'هو عبد العزيز بن عبد الله بن عبد الرحمن بن محمد بن عبد الله آل باز. '
          'ولد في مدينة الرياض في الثاني عشر من ذي الحجة سنة 1330هـ. '
          'كان بصيراً ثم أصيب بمرض في عينيه عام 1346هـ وفقد بصره بالكامل عام 1350هـ. '
          'حفظ القرآن الكريم قبل البلوغ، ثم جدَّ في طلب العلم على يد العلماء في الرياض. '
          'عُرف بعلمه الواسع وتواضعه الجم وصبره على التعليم والإفتاء. '
          'تولى رئاسة الجامعة الإسلامية بالمدينة المنورة ثم رئاسة إدارات البحوث العلمية والإفتاء '
          'والدعوة والإرشاد ثم مفتياً عاماً للمملكة العربية السعودية ورئيساً لهيئة كبار العلماء. '
          'توفي رحمه الله في السابع والعشرين من محرم عام 1420هـ.',
      booksCount: 2,
      lessonsCount: 40,
    ),
    const SheikhModel(
      id: 'sheikh_fawzan',
      name: 'الشيخ صالح الفوزان',
      shortBio:
          'عضو هيئة كبار العلماء واللجنة الدائمة للبحوث العلمية والإفتاء.',
      fullBio:
          'هو صالح بن فوزان بن عبد الله الفوزان، من آل فوزان من أهالي الشماسية التابعة لمنطقة القصيم. '
          'ولد عام 1354هـ، توفي والده وهو صغير فتربى في أسرته. درس القرآن الكريم وتعلم مبادئ القراءة '
          'والكتابة على يد إمام مسجد البلدة. التحق بمدرسة الفيصلية في بريدة ثم انتقل إلى الرياض '
          'ودرس في كلية الشريعة. حصل على الماجستير والدكتوراه من المعهد العالي للقضاء. '
          'عُيِّن عضواً في هيئة كبار العلماء وعضواً في اللجنة الدائمة للبحوث العلمية والإفتاء. '
          'له مؤلفات كثيرة في العقيدة والفقه وشروحات على متون عديدة.',
      booksCount: 3,
      lessonsCount: 50,
    ),
    const SheikhModel(
      id: 'sheikh_albadr',
      name: 'الشيخ عبد الرزاق البدر',
      shortBio:
          'عالم وداعية سعودي، أستاذ في الجامعة الإسلامية بالمدينة المنورة.',
      fullBio:
          'هو عبد الرزاق بن عبد المحسن بن حمد العباد البدر. ولد في مدينة الزلفي عام 1382هـ، '
          'ونشأ في المدينة النبوية. حصل على البكالوريوس من كلية الشريعة بالجامعة الإسلامية بالمدينة المنورة، '
          'ثم حصل على الماجستير ثم الدكتوراه في العقيدة. يعمل أستاذاً في قسم العقيدة بالجامعة الإسلامية. '
          'له عناية كبيرة بشرح المتون العلمية في العقيدة والحديث والفقه. '
          'يُعرف بأسلوبه العلمي الرصين وعنايته بالتأصيل والتقعيد. '
          'له مؤلفات عديدة ودروس علمية مسجلة استفاد منها طلاب العلم في أنحاء العالم.',
      booksCount: 2,
      lessonsCount: 35,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  //  الكتب والمتون
  // ═══════════════════════════════════════════════════════════════════════════

  static final List<BookModel> books = [
    // ── كتب العقيدة ──────────────────────────────────────────────────────
    const BookModel(
      id: 'book_tawheed',
      categoryId: 'cat_aqeedah',
      title: 'كتاب التوحيد',
      author: 'الإمام محمد بن عبد الوهاب',
      description:
          'كتاب التوحيد الذي هو حق الله على العبيد، من أهم كتب العقيدة الإسلامية. '
          'يتناول توحيد العبادة وبيان أنواع الشرك والبدع التي تناقض التوحيد. '
          'مؤلفه هو الإمام المجدد محمد بن عبد الوهاب رحمه الله.',
      seriesCount: 2,
    ),
    const BookModel(
      id: 'book_usool_thalatha',
      categoryId: 'cat_aqeedah',
      title: 'الأصول الثلاثة',
      author: 'الإمام محمد بن عبد الوهاب',
      description:
          'متن مختصر في أصول الدين الثلاثة التي يجب على كل مسلم معرفتها: '
          'معرفة العبد ربه، ودينه، ونبيه صلى الله عليه وسلم.',
      seriesCount: 2,
    ),
    const BookModel(
      id: 'book_qawaid_arba',
      categoryId: 'cat_aqeedah',
      title: 'القواعد الأربع',
      author: 'الإمام محمد بن عبد الوهاب',
      description:
          'رسالة مختصرة لطيفة في بيان أربع قواعد عظيمة في التوحيد، '
          'يُعرف بها الفرق بين التوحيد والشرك.',
      seriesCount: 1,
    ),

    // ── كتب الفقه ────────────────────────────────────────────────────────
    const BookModel(
      id: 'book_zaad',
      categoryId: 'cat_fiqh',
      title: 'زاد المستقنع',
      author: 'الحجاوي',
      description:
          'مختصر في الفقه الحنبلي اعتنى به العلماء شرحاً وتدريساً. '
          'يعد من أهم المتون الفقهية على مذهب الإمام أحمد بن حنبل رحمه الله.',
      seriesCount: 2,
    ),
    const BookModel(
      id: 'book_umdah',
      categoryId: 'cat_fiqh',
      title: 'عمدة الأحكام',
      author: 'الحافظ عبد الغني المقدسي',
      description:
          'كتاب جامع لأحاديث الأحكام المتفق عليها بين البخاري ومسلم. '
          'من أنفع كتب الأحكام لطالب العلم المبتدئ.',
      seriesCount: 1,
    ),

    // ── كتب الحديث ───────────────────────────────────────────────────────
    const BookModel(
      id: 'book_arbaeen',
      categoryId: 'cat_hadith',
      title: 'الأربعون النووية',
      author: 'الإمام النووي',
      description:
          'اثنان وأربعون حديثاً جمعها الإمام النووي رحمه الله، تشتمل على قواعد عظيمة '
          'من قواعد الإسلام وأصوله. وهي أحاديث جامعة لأصول الدين.',
      seriesCount: 2,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  //  السلاسل (الشروحات) - نقطة الربط بين الشيوخ والكتب
  // ═══════════════════════════════════════════════════════════════════════════

  static final List<SeriesModel> series = [
    // ── شروحات كتاب التوحيد ──────────────────────────────────────────────
    const SeriesModel(
      id: 'series_tawheed_uthaymeen',
      bookId: 'book_tawheed',
      sheikhId: 'sheikh_uthaymeen',
      categoryId: 'cat_aqeedah',
      title: 'شرح كتاب التوحيد - الشيخ ابن عثيمين',
      lessonsCount: 10,
    ),
    const SeriesModel(
      id: 'series_tawheed_fawzan',
      bookId: 'book_tawheed',
      sheikhId: 'sheikh_fawzan',
      categoryId: 'cat_aqeedah',
      title: 'شرح كتاب التوحيد - الشيخ الفوزان',
      lessonsCount: 8,
    ),

    // ── شروحات الأصول الثلاثة ────────────────────────────────────────────
    const SeriesModel(
      id: 'series_usool_uthaymeen',
      bookId: 'book_usool_thalatha',
      sheikhId: 'sheikh_uthaymeen',
      categoryId: 'cat_aqeedah',
      title: 'شرح الأصول الثلاثة - الشيخ ابن عثيمين',
      lessonsCount: 6,
    ),
    const SeriesModel(
      id: 'series_usool_albadr',
      bookId: 'book_usool_thalatha',
      sheikhId: 'sheikh_albadr',
      categoryId: 'cat_aqeedah',
      title: 'شرح الأصول الثلاثة - الشيخ عبد الرزاق البدر',
      lessonsCount: 5,
    ),

    // ── شرح القواعد الأربع ────────────────────────────────────────────────
    const SeriesModel(
      id: 'series_qawaid_fawzan',
      bookId: 'book_qawaid_arba',
      sheikhId: 'sheikh_fawzan',
      categoryId: 'cat_aqeedah',
      title: 'شرح القواعد الأربع - الشيخ الفوزان',
      lessonsCount: 3,
    ),

    // ── شروحات زاد المستقنع ──────────────────────────────────────────────
    const SeriesModel(
      id: 'series_zaad_uthaymeen',
      bookId: 'book_zaad',
      sheikhId: 'sheikh_uthaymeen',
      categoryId: 'cat_fiqh',
      title: 'شرح زاد المستقنع - الشيخ ابن عثيمين',
      lessonsCount: 12,
    ),
    const SeriesModel(
      id: 'series_zaad_fawzan',
      bookId: 'book_zaad',
      sheikhId: 'sheikh_fawzan',
      categoryId: 'cat_fiqh',
      title: 'شرح زاد المستقنع - الشيخ الفوزان',
      lessonsCount: 10,
    ),

    // ── شرح عمدة الأحكام ─────────────────────────────────────────────────
    const SeriesModel(
      id: 'series_umdah_binbaz',
      bookId: 'book_umdah',
      sheikhId: 'sheikh_bin_baz',
      categoryId: 'cat_fiqh',
      title: 'شرح عمدة الأحكام - الشيخ ابن باز',
      lessonsCount: 8,
    ),

    // ── شروحات الأربعون النووية ──────────────────────────────────────────
    const SeriesModel(
      id: 'series_arbaeen_uthaymeen',
      bookId: 'book_arbaeen',
      sheikhId: 'sheikh_uthaymeen',
      categoryId: 'cat_hadith',
      title: 'شرح الأربعون النووية - الشيخ ابن عثيمين',
      lessonsCount: 7,
    ),
    const SeriesModel(
      id: 'series_arbaeen_albadr',
      bookId: 'book_arbaeen',
      sheikhId: 'sheikh_albadr',
      categoryId: 'cat_hadith',
      title: 'شرح الأربعون النووية - الشيخ عبد الرزاق البدر',
      lessonsCount: 6,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  //  الدروس
  // ═══════════════════════════════════════════════════════════════════════════

  static final List<LessonModel> lessons = [
    // ── دروس شرح كتاب التوحيد - ابن عثيمين ─────────────────────────────
    const LessonModel(
      id: 'lesson_tawheed_uth_01',
      seriesId: 'series_tawheed_uthaymeen',
      title: 'مقدمة كتاب التوحيد وبيان فضل التوحيد',
      order: 1,
      duration: '45:30',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/001.mp3',
      transcript:
          'بسم الله الرحمن الرحيم، الحمد لله رب العالمين والصلاة والسلام على نبينا محمد وعلى آله وصحبه أجمعين. '
          'أما بعد: فإن كتاب التوحيد الذي هو حق الله على العبيد للإمام المجدد محمد بن عبد الوهاب رحمه الله تعالى '
          'من أنفع الكتب المؤلفة في باب التوحيد، وقد بين فيه رحمه الله حقيقة التوحيد وأقسامه وفضله وما يكفر من الذنوب.',
    ),
    const LessonModel(
      id: 'lesson_tawheed_uth_02',
      seriesId: 'series_tawheed_uthaymeen',
      title: 'باب فضل التوحيد وما يكفر من الذنوب',
      order: 2,
      duration: '52:15',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/112.mp3',
      transcript:
          'قال المؤلف رحمه الله تعالى: باب فضل التوحيد وما يكفر من الذنوب. '
          'وقول الله تعالى: الذين آمنوا ولم يلبسوا إيمانهم بظلم أولئك لهم الأمن وهم مهتدون. '
          'عن عبادة بن الصامت رضي الله عنه قال: قال رسول الله صلى الله عليه وسلم: من شهد أن لا إله إلا الله وحده لا شريك له وأن محمداً عبده ورسوله أدخله الله الجنة على ما كان من العمل.',
    ),
    const LessonModel(
      id: 'lesson_tawheed_uth_03',
      seriesId: 'series_tawheed_uthaymeen',
      title: 'باب من حقق التوحيد دخل الجنة بغير حساب',
      order: 3,
      duration: '48:00',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/113.mp3',
      transcript:
          'قال المؤلف رحمه الله تعالى: باب من حقق التوحيد دخل الجنة بغير حساب ولا عذاب. '
          'تحقيق التوحيد تخليصه وتنقيته من شوائب الشرك والبدع والمعاصي، '
          'وقوله تعالى: إن إبراهيم كان أمة قانتاً لله حنيفاً ولم يك من المشركين.',
    ),
    const LessonModel(
      id: 'lesson_tawheed_uth_04',
      seriesId: 'series_tawheed_uthaymeen',
      title: 'باب الخوف من الشرك',
      order: 4,
      duration: '41:20',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/114.mp3',
      // بدون تفريغ لاختبار حالة عدم توفر التفريغ وزر الواتساب
    ),
    const LessonModel(
      id: 'lesson_tawheed_uth_05',
      seriesId: 'series_tawheed_uthaymeen',
      title: 'باب الدعاء إلى شهادة أن لا إله إلا الله',
      order: 5,
      duration: '50:45',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/108.mp3',
      videoUrl: 'https://www.youtube.com/watch?v=7_i1wN8eS74',
      transcript:
          'قال الإمام رحمه الله: باب الدعاء إلى شهادة أن لا إله إلا الله. '
          'وقول الله تعالى: قل هذه سبيلي أدعو إلى الله على بصيرة أنا ومن اتبعني وسبحان الله وما أنا من المشركين.',
    ),

    // ── دروس شرح كتاب التوحيد - الفوزان ──────────────────────────────────
    const LessonModel(
      id: 'lesson_tawheed_fwz_01',
      seriesId: 'series_tawheed_fawzan',
      title: 'المقدمة وترجمة المؤلف',
      order: 1,
      duration: '38:10',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/001.mp3',
      transcript:
          'الحمد لله رب العالمين وصلى الله وسلم وبارك على عبده ورسوله نبينا محمد. '
          'هذا الكتاب كتاب عظيم ألفه الشيخ الإمام المجدد محمد بن عبد الوهاب رحمه الله تعالى في بيان عقيدة التوحيد.',
    ),
    const LessonModel(
      id: 'lesson_tawheed_fwz_02',
      seriesId: 'series_tawheed_fawzan',
      title: 'تعريف التوحيد وأقسامه',
      order: 2,
      duration: '42:30',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/110.mp3',
    ),
    const LessonModel(
      id: 'lesson_tawheed_fwz_03',
      seriesId: 'series_tawheed_fawzan',
      title: 'باب تفسير التوحيد وشهادة أن لا إله إلا الله',
      order: 3,
      duration: '44:55',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/112.mp3',
    ),

    // ── دروس شرح الأصول الثلاثة - ابن عثيمين ───────────────────────────
    const LessonModel(
      id: 'lesson_usool_uth_01',
      seriesId: 'series_usool_uthaymeen',
      title: 'مقدمة الأصول الثلاثة والمسائل الأربع',
      order: 1,
      duration: '35:20',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/001.mp3',
      transcript:
          'بسم الله الرحمن الرحيم. قال المؤلف رحمه الله تعالى: اعلم رحمك الله أنه يجب علينا '
          'تعلم أربع مسائل: الأولى العلم وهو معرفة الله ومعرفة نبيه ومعرفة دين الإسلام بالأدلة، '
          'الثانية العمل به، الثالثة الدعوة إليه، الرابعة الصبر على الأذى فيه.',
    ),
    const LessonModel(
      id: 'lesson_usool_uth_02',
      seriesId: 'series_usool_uthaymeen',
      title: 'الأصل الأول: معرفة العبد ربه',
      order: 2,
      duration: '40:15',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/112.mp3',
    ),
    const LessonModel(
      id: 'lesson_usool_uth_03',
      seriesId: 'series_usool_uthaymeen',
      title: 'الأصل الثاني: معرفة دين الإسلام بالأدلة',
      order: 3,
      duration: '47:30',
      audioUrl: 'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/113.mp3',
      videoUrl: 'https://www.youtube.com/watch?v=7_i1wN8eS74',
    ),

    // ── دروس شرح الأصول الثلاثة - البدر ─────────────────────────────────
    const LessonModel(
      id: 'lesson_usool_bdr_01',
      seriesId: 'series_usool_albadr',
      title: 'فضل العلم والعمل والدعوة والصبر',
      order: 1,
      duration: '55:00',
      audioUrl: 'https://example.com/audio/usool_bdr_01.mp3',
      transcript:
          'إن الحمد لله نحمده ونستعينه ونستغفره ونعوذ بالله من شرور أنفسنا ومن سيئات أعمالنا. '
          'هذا المتن المبارك الأصول الثلاثة وأدلتها للإمام المجدد محمد بن عبد الوهاب رحمه الله...',
    ),
    const LessonModel(
      id: 'lesson_usool_bdr_02',
      seriesId: 'series_usool_albadr',
      title: 'معرفة الله بآياته ومخلوقاته',
      order: 2,
      duration: '50:10',
      audioUrl: 'https://example.com/audio/usool_bdr_02.mp3',
    ),

    // ── دروس شرح زاد المستقنع - ابن عثيمين ─────────────────────────────
    const LessonModel(
      id: 'lesson_zaad_uth_01',
      seriesId: 'series_zaad_uthaymeen',
      title: 'كتاب الطهارة - أقسام المياه',
      order: 1,
      duration: '58:30',
      audioUrl: 'https://example.com/audio/zaad_uth_01.mp3',
      transcript:
          'بسم الله الرحمن الرحيم. كتاب الطهارة. الطهارة في اللغة: النظافة والنزاهة عن الأقذار. '
          'وفي الاصطلاح: ارتفاع الحدث وما في معناه وزوال الخبث...',
    ),
    const LessonModel(
      id: 'lesson_zaad_uth_02',
      seriesId: 'series_zaad_uthaymeen',
      title: 'كتاب الطهارة - آداب قضاء الحاجة',
      order: 2,
      duration: '45:20',
      audioUrl: 'https://example.com/audio/zaad_uth_02.mp3',
    ),
    const LessonModel(
      id: 'lesson_zaad_uth_03',
      seriesId: 'series_zaad_uthaymeen',
      title: 'كتاب الطهارة - فروض الوضوء وصفته',
      order: 3,
      duration: '52:00',
      audioUrl: 'https://example.com/audio/zaad_uth_03.mp3',
      videoUrl: 'https://example.com/video/zaad_uth_03.mp4',
    ),

    // ── دروس شرح عمدة الأحكام - ابن باز ─────────────────────────────────
    const LessonModel(
      id: 'lesson_umdah_baz_01',
      seriesId: 'series_umdah_binbaz',
      title: 'كتاب الطهارة - حديث عمر في النية',
      order: 1,
      duration: '40:00',
      audioUrl: 'https://example.com/audio/umdah_baz_01.mp3',
      transcript:
          'الحمد لله وحده والصلاة والسلام على من لا نبي بعده. قال المصنف رحمه الله: '
          'عن أمير المؤمنين عمر بن الخطاب رضي الله عنه قال: سمعت رسول الله صلى الله عليه وسلم '
          'يقول: إنما الأعمال بالنيات...',
    ),
    const LessonModel(
      id: 'lesson_umdah_baz_02',
      seriesId: 'series_umdah_binbaz',
      title: 'كتاب الطهارة - المسح على الخفين',
      order: 2,
      duration: '38:45',
      audioUrl: 'https://example.com/audio/umdah_baz_02.mp3',
    ),

    // ── دروس شرح الأربعون النووية - ابن عثيمين ──────────────────────────
    const LessonModel(
      id: 'lesson_arbaeen_uth_01',
      seriesId: 'series_arbaeen_uthaymeen',
      title: 'حديث إنما الأعمال بالنيات',
      order: 1,
      duration: '35:00',
      audioUrl: 'https://example.com/audio/arbaeen_uth_01.mp3',
      transcript:
          'الحديث الأول: عن أمير المؤمنين أبي حفص عمر بن الخطاب رضي الله عنه قال: '
          'سمعت رسول الله صلى الله عليه وسلم يقول: إنما الأعمال بالنيات وإنما لكل امرئ ما نوى...',
    ),
    const LessonModel(
      id: 'lesson_arbaeen_uth_02',
      seriesId: 'series_arbaeen_uthaymeen',
      title: 'حديث جبريل في بيان الإسلام والإيمان والإحسان',
      order: 2,
      duration: '55:30',
      audioUrl: 'https://example.com/audio/arbaeen_uth_02.mp3',
      videoUrl: 'https://example.com/video/arbaeen_uth_02.mp4',
    ),
    const LessonModel(
      id: 'lesson_arbaeen_uth_03',
      seriesId: 'series_arbaeen_uthaymeen',
      title: 'حديث بني الإسلام على خمس',
      order: 3,
      duration: '42:15',
      audioUrl: 'https://example.com/audio/arbaeen_uth_03.mp3',
    ),

    // ── دروس شرح الأربعون النووية - البدر ────────────────────────────────
    const LessonModel(
      id: 'lesson_arbaeen_bdr_01',
      seriesId: 'series_arbaeen_albadr',
      title: 'مقدمة وحديث الأعمال بالنيات',
      order: 1,
      duration: '48:20',
      audioUrl: 'https://example.com/audio/arbaeen_bdr_01.mp3',
      transcript:
          'الحمد لله رب العالمين وأشهد أن لا إله إلا الله وحده لا شريك له وأشهد أن محمداً '
          'عبده ورسوله صلى الله عليه وعلى آله وأصحابه أجمعين. أما بعد فهذه الأحاديث النووية '
          'التي جمعها الإمام النووي رحمه الله أحاديث عظيمة...',
    ),
    const LessonModel(
      id: 'lesson_arbaeen_bdr_02',
      seriesId: 'series_arbaeen_albadr',
      title: 'حديث أركان الإسلام وأركان الإيمان',
      order: 2,
      duration: '52:00',
      audioUrl: 'https://example.com/audio/arbaeen_bdr_02.mp3',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  //  دوال الاستعلام (Query Helpers)
  // ═══════════════════════════════════════════════════════════════════════════

  /// جلب الكتب حسب القسم
  static List<BookModel> getBooksByCategory(String categoryId) {
    return books.where((book) => book.categoryId == categoryId).toList();
  }

  /// جلب الشروحات حسب الكتاب
  static List<SeriesModel> getSeriesByBook(String bookId) {
    return series.where((s) => s.bookId == bookId).toList();
  }

  /// جلب الشروحات حسب الشيخ
  static List<SeriesModel> getSeriesBySheikh(String sheikhId) {
    return series.where((s) => s.sheikhId == sheikhId).toList();
  }

  /// جلب الشروحات حسب القسم
  static List<SeriesModel> getSeriesByCategory(String categoryId) {
    return series.where((s) => s.categoryId == categoryId).toList();
  }

  /// جلب الدروس حسب السلسلة
  static List<LessonModel> getLessonsBySeries(String seriesId) {
    return lessons
        .where((lesson) => lesson.seriesId == seriesId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// جلب شيخ حسب المعرّف
  static SheikhModel? getSheikhById(String sheikhId) {
    try {
      return sheikhs.firstWhere((s) => s.id == sheikhId);
    } catch (_) {
      return null;
    }
  }

  /// جلب كتاب حسب المعرّف
  static BookModel? getBookById(String bookId) {
    try {
      return books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  /// جلب قسم حسب المعرّف
  static CategoryModel? getCategoryById(String categoryId) {
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  /// مقولة اليوم - قائمة مقولات علمية للعرض في الصفحة الرئيسية
  static final List<Map<String, String>> dailyQuotes = [
    {
      'text':
          'كنت لا أكتب شيئًا إلا حفظته، وإني الآن لكأني أنظر إلى أكثر من سبعين ألف حديث في كتابي',
      'author': 'إسحاق بن راهويه',
    },
    {
      'text': 'من لم يصبر على ذل التعلم ساعة بقي في ذل الجهل أبداً',
      'author': 'الإمام الشافعي',
    },
    {
      'text': 'العلم لا يعطيك بعضه حتى تعطيه كلك',
      'author': 'الإمام الزهري',
    },
    {
      'text': 'من طلب العلم لله لم يزدد بالعلم إلا تواضعاً وبذلاً',
      'author': 'سفيان الثوري',
    },
    {
      'text':
          'لا ينبغي لأحد عنده شيء من العلم أن يضيّع نفسه، فالعلم يُحتاج إليه',
      'author': 'الإمام أحمد بن حنبل',
    },
  ];
}

