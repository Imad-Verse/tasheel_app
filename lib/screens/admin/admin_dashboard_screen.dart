import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../providers/audio_provider.dart';
import 'admin_login_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// لوحة التحكم الإدارية الشاملة (AdminDashboardScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// تتيح الإدارة الكاملة لـ 6 أقسام رئيسية:
/// 1. الأقسام العلمية (Categories Management).
/// 2. الشيوخ والعلماء (Sheikhs Management).
/// 3. الكتب والمتون (Books Management).
/// 4. الشروحات العلمية (Series Management) مع قوائم منسدلة مترابطة.
/// 5. إدارة الدروس (Lessons Management) بإضافة فردية وإضافة جماعية (Bulk Add).
/// 6. محرر التفريغات السريعة (Quick Transcripts Editor).
/// ═══════════════════════════════════════════════════════════════════════════
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSeedingData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── رفع البيانات الأولية إلى السحابة ──────────────────────────────────────
  Future<void> _handleSeedData() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (!appProvider.isFirebaseConnected) {
      _showSnackBar(
        'تنبيه: Firebase غير مهيأ حالياً في هذا الجهاز. البيانات محفوظة وتعمل بكفاءة في وضع التخزين المحلي.',
        isError: false,
      );
      return;
    }

    setState(() => _isSeedingData = true);
    try {
      final success = await appProvider.seedDataToFirestore();
      if (mounted) {
        if (success) {
          _showSnackBar(
            'تم رفع وتحديث جميع البيانات في Cloud Firestore بنجاح!',
          );
        } else {
          _showSnackBar(
            'تعذر رفع البيانات، يرجى مراجعة إعدادات وصلاحيات Firebase.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('حدث خطأ أثناء الرفع: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSeedingData = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.readexPro(color: AppColors.textWhite),
        ),
        backgroundColor: isError
            ? Colors.red.shade800
            : AppColors.primaryDarkBrown,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleLogout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      body: Column(
        children: [
          // ── 1. الهيدر العلوي وشريط الحالة ────────────────────────────────
          _buildTopHeader(appProvider),

          // ── 2. شريط التبويبات الستة ───────────────────────────────────────
          _buildTabBar(),

          // ── 3. صفحات الأقسام الإدارية ─────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CategoriesTab(appProvider: appProvider),
                _SheikhsTab(appProvider: appProvider),
                _BooksTab(appProvider: appProvider),
                _SeriesTab(appProvider: appProvider),
                _LessonsTab(appProvider: appProvider),
                _TranscriptsTab(appProvider: appProvider),
                _NotificationsAndUpdatesTab(appProvider: appProvider),
                _AboutAppTab(appProvider: appProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── الهيدر وشريط الحالة ──────────────────────────────────────────────────
  Widget _buildTopHeader(AppProvider appProvider) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isConnected = appProvider.isFirebaseConnected;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.primaryDarkBrown,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // زر العودة للتطبيق في اليمين
              IconButton(
                tooltip: 'العودة للتطبيق',
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textGoldLight,
                ),
                onPressed: () => Navigator.pop(context),
              ),

              const SizedBox(width: 4),

              // العنوان
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لوحة إدارة تسهيل',
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGoldLight,
                      ),
                    ),
                    Text(
                      'إدارة المحتوى والمزامنة السحابية',
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        color: AppColors.textWhite.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // زر رفع البيانات الأولية للسحابة (Seed Data)
              ElevatedButton.icon(
                onPressed: _isSeedingData ? null : _handleSeedData,
                icon: _isSeedingData
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textGoldLight,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 16),
                label: Text(
                  'رفع للسحابة',
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLightBrown,
                  foregroundColor: AppColors.textGoldLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.goldMuted),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // زر تسجيل الخروج في أقصى اليسار
              IconButton(
                tooltip: 'تسجيل الخروج',
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.textGoldLight,
                ),
                onPressed: _handleLogout,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // شريط حالة الاتصال
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green.shade900.withValues(alpha: 0.6)
                  : AppColors.primaryLightBrown.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected
                    ? Colors.green.shade400
                    : AppColors.goldMuted,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected
                        ? Colors.greenAccent
                        : AppColors.textGoldLight,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected
                      ? 'قاعدة البيانات: متصل بـ Cloud Firestore'
                      : 'قاعدة البيانات: وضع الحفظ المحلي (SharedPreferences)',
                  style: GoogleFonts.readexPro(
                    fontSize: 11,
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── شريط التبويبات الستة ──────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppColors.cardWhite,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.iconGold,
        indicatorWeight: 3,
        labelColor: AppColors.primaryDarkBrown,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.readexPro(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.readexPro(fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.category_rounded, size: 20), text: 'الأقسام'),
          Tab(icon: Icon(Icons.people_alt_rounded, size: 20), text: 'الشيوخ'),
          Tab(icon: Icon(Icons.menu_book_rounded, size: 20), text: 'الكتب'),
          Tab(
            icon: Icon(Icons.library_books_rounded, size: 20),
            text: 'الشروحات',
          ),
          Tab(icon: Icon(Icons.audiotrack_rounded, size: 20), text: 'الدروس'),
          Tab(icon: Icon(Icons.subtitles_rounded, size: 20), text: 'التفريغات'),
          Tab(
            icon: Icon(Icons.notifications_active_rounded, size: 20),
            text: 'الإشعارات والتحديثات',
          ),
          Tab(
            icon: Icon(Icons.info_outline_rounded, size: 20),
            text: 'عن التطبيق والتواصل',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. تبويب إدارة الأقسام العلمية (Categories Tab)
// ═══════════════════════════════════════════════════════════════════════════
class _CategoriesTab extends StatelessWidget {
  final AppProvider appProvider;
  const _CategoriesTab({required this.appProvider});

  void _openAddEditDialog(BuildContext context, {CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedIcon = category?.iconName ?? 'category';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.scaffoldCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            category == null ? 'إضافة قسم علمي جديد' : 'تعديل القسم العلمي',
            style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkBrown,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: GoogleFonts.readexPro(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'اسم القسم (مثال: متون العقيدة)',
                    filled: true,
                    fillColor: AppColors.cardWhite,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'يرجى إدخال اسم القسم'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedIcon,
                  decoration: const InputDecoration(
                    labelText: 'رمز الأيقونة',
                    filled: true,
                    fillColor: AppColors.cardWhite,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'category',
                      child: Text('تصنيف عام'),
                    ),
                    DropdownMenuItem(
                      value: 'menu_book',
                      child: Text('كتاب شرعي'),
                    ),
                    DropdownMenuItem(
                      value: 'balance',
                      child: Text('ميزان الفقه'),
                    ),
                    DropdownMenuItem(
                      value: 'mosque',
                      child: Text('مسجد وعقيدة'),
                    ),
                    DropdownMenuItem(
                      value: 'auto_stories',
                      child: Text('متون وحفظ'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedIcon = val);
                  },
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkBrown,
                foregroundColor: AppColors.textGoldLight,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                if (category == null) {
                  final newCat = CategoryModel(
                    id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    iconName: selectedIcon,
                  );
                  await appProvider.addCategory(newCat);
                } else {
                  final updated = category.copyWith(
                    name: nameController.text.trim(),
                    iconName: selectedIcon,
                  );
                  await appProvider.updateCategory(updated);
                }
              },
              child: Text(
                category == null ? 'إضافة' : 'حفظ التعديل',
                style: GoogleFonts.readexPro(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف القسم تتابعياً',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
        content: Text(
          '⚠️ تحذير: حذف قسم "${cat.name}" سيؤدي إلى حذف تتابعي تلقائي لجميع:\n'
          '• الكتب التابعة لهذا القسم\n'
          '• كافة الشروحات المرتبطة بتلك الكتب\n'
          '• جميع الدروس والتفريغات الصوتية والنصية التابعة لها\n'
          '• أي شيخ ليس له شروحات إلا في هذا القسم\n\n'
          'هل أنت متأكد من الاستمرار في الحذف؟',
          style: GoogleFonts.readexPro(fontSize: 13, height: 1.5),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await appProvider.deleteCategory(cat.id);
            },
            child: Text(
              'تأكيد الحذف التتابعي',
              style: GoogleFonts.readexPro(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = appProvider.categories;

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDarkBrown,
        foregroundColor: AppColors.textGoldLight,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'إضافة قسم',
          style: GoogleFonts.readexPro(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _openAddEditDialog(context),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Card(
            color: AppColors.cardWhite,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.dividerLight),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightBrown.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: AppColors.iconGold,
                ),
              ),
              title: Text(
                cat.name,
                style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${cat.booksCount} كتب • ${cat.sheikhsCount} شيوخ • ${cat.lessonsCount} درس',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.iconGold,
                      size: 20,
                    ),
                    onPressed: () => _openAddEditDialog(context, category: cat),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    onPressed: () => _confirmDelete(context, cat),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. تبويب إدارة الشيوخ والعلماء (Sheikhs Tab)
// ═══════════════════════════════════════════════════════════════════════════
class _SheikhsTab extends StatelessWidget {
  final AppProvider appProvider;
  const _SheikhsTab({required this.appProvider});

  void _openAddEditDialog(BuildContext context, {SheikhModel? sheikh}) {
    final nameController = TextEditingController(text: sheikh?.name ?? '');
    final shortBioController = TextEditingController(
      text: sheikh?.shortBio ?? '',
    );
    final fullBioController = TextEditingController(
      text: sheikh?.fullBio ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool sendNotification = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.scaffoldCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            sheikh == null ? 'إضافة شيخ جديد' : 'تعديل بيانات الشيخ',
            style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkBrown,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: GoogleFonts.readexPro(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'اسم الشيخ (مثال: الشيخ عبد الرزاق البدر)',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'يرجى إدخال اسم الشيخ'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: shortBioController,
                    style: GoogleFonts.readexPro(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'نبذة قصيرة',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fullBioController,
                    style: GoogleFonts.readexPro(fontSize: 14),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'السيرة والتفاصيل',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                  ),
                  if (sheikh == null) ...[
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: sendNotification,
                      title: Text(
                        'إرسال إشعار للمستخدمين بهذه الإضافة',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      activeColor: AppColors.primaryDarkBrown,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setDialogState(() {
                          sendNotification = val ?? true;
                        });
                      },
                    ),
                  ],
                ],
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkBrown,
                foregroundColor: AppColors.textGoldLight,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                if (sheikh == null) {
                  final newSheikh = SheikhModel(
                    id: 'sheikh_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    shortBio: shortBioController.text.trim(),
                    fullBio: fullBioController.text.trim(),
                  );
                  await appProvider.addSheikh(newSheikh);
                  if (sendNotification) {
                    await appProvider.sendNotification(
                      title: 'إضافة شيخ جديد',
                      body:
                          'تمت إضافة صفحة وشروحات ${newSheikh.name} إلى تطبيق تسهيل.',
                      type: 'sheikh',
                    );
                  }
                } else {
                  final updated = sheikh.copyWith(
                    name: nameController.text.trim(),
                    shortBio: shortBioController.text.trim(),
                    fullBio: fullBioController.text.trim(),
                  );
                  await appProvider.updateSheikh(updated);
                }
              },
              child: Text(
                sheikh == null ? 'إضافة' : 'حفظ التعديل',
                style: GoogleFonts.readexPro(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SheikhModel sheikh) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف الشيخ تتابعياً',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
        content: Text(
          '⚠️ تحذير: حذف الشيخ "${sheikh.name}" سيؤدي إلى حذف تتابعي تلقائي لجميع:\n'
          '• كافة الشروحات المسجلة للشيخ\n'
          '• جميع الدروس والتفريغات التابعة لشروحاته\n'
          '• أي كتاب لم يعد له أي شرح آخر في التطبيق\n\n'
          'هل أنت متأكد من الاستمرار في الحذف؟',
          style: GoogleFonts.readexPro(fontSize: 13, height: 1.5),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await appProvider.deleteSheikh(sheikh.id);
            },
            child: Text(
              'تأكيد الحذف التتابعي',
              style: GoogleFonts.readexPro(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheikhs = appProvider.sheikhs;

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDarkBrown,
        foregroundColor: AppColors.textGoldLight,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          'إضافة شيخ',
          style: GoogleFonts.readexPro(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _openAddEditDialog(context),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: sheikhs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final sh = sheikhs[index];
          return Card(
            color: AppColors.cardWhite,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.dividerLight),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightBrown.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.iconGold,
                ),
              ),
              title: Text(
                sh.name,
                style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${sh.booksCount} شروحات • ${sh.lessonsCount} درس\n${sh.shortBio}',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.iconGold,
                      size: 20,
                    ),
                    onPressed: () => _openAddEditDialog(context, sheikh: sh),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    onPressed: () => _confirmDelete(context, sh),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. تبويب إدارة الكتب والمتون (Books Tab)
// ═══════════════════════════════════════════════════════════════════════════
class _BooksTab extends StatefulWidget {
  final AppProvider appProvider;
  const _BooksTab({required this.appProvider});

  @override
  State<_BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<_BooksTab> {
  String? _selectedCategoryFilter;

  void _openAddEditDialog(BuildContext context, {BookModel? book}) {
    final titleController = TextEditingController(text: book?.title ?? '');
    final authorController = TextEditingController(text: book?.author ?? '');
    final descController = TextEditingController(text: book?.description ?? '');
    String selectedCatId =
        book?.categoryId ??
        (_selectedCategoryFilter ??
            (widget.appProvider.categories.isNotEmpty
                ? widget.appProvider.categories.first.id
                : ''));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.scaffoldCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            book == null ? 'إضافة كتاب أو متن جديد' : 'تعديل بيانات الكتاب',
            style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkBrown,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اختيار القسم
                  DropdownButtonFormField<String>(
                    initialValue: selectedCatId.isNotEmpty
                        ? selectedCatId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'القسم العلمي التابع له',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                    items: widget.appProvider.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCatId = val);
                      }
                    },
                    validator: (val) =>
                        val == null ? 'يرجى اختيار القسم' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    style: GoogleFonts.readexPro(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'عنوان الكتاب (مثال: كتاب التوحيد)',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'يرجى إدخال العنوان'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: authorController,
                    style: GoogleFonts.readexPro(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'المؤلف / الماتن',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'يرجى إدخال المؤلف'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    style: GoogleFonts.readexPro(fontSize: 14),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'وصف مختصر للمتن',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                  ),
                ],
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkBrown,
                foregroundColor: AppColors.textGoldLight,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                if (book == null) {
                  final newBook = BookModel(
                    id: 'book_${DateTime.now().millisecondsSinceEpoch}',
                    categoryId: selectedCatId,
                    title: titleController.text.trim(),
                    author: authorController.text.trim(),
                    description: descController.text.trim(),
                  );
                  await widget.appProvider.addBook(newBook);
                } else {
                  final updated = book.copyWith(
                    categoryId: selectedCatId,
                    title: titleController.text.trim(),
                    author: authorController.text.trim(),
                    description: descController.text.trim(),
                  );
                  await widget.appProvider.updateBook(updated);
                }
              },
              child: Text(
                book == null ? 'إضافة' : 'حفظ التعديل',
                style: GoogleFonts.readexPro(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف الكتاب تتابعياً',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
        content: Text(
          '⚠️ تحذير: حذف كتاب "${book.title}" سيؤدي إلى حذف تتابعي تلقائي لجميع:\n'
          '• كافة الشروحات المسجلة لهذا الكتاب\n'
          '• جميع الدروس والتفريغات الصوتية والنصية التابعة لها\n\n'
          'هل أنت متأكد من الاستمرار في الحذف؟',
          style: GoogleFonts.readexPro(fontSize: 13, height: 1.5),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.appProvider.deleteBook(book.id);
            },
            child: Text(
              'تأكيد الحذف التتابعي',
              style: GoogleFonts.readexPro(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = _selectedCategoryFilter == null
        ? widget.appProvider.books
        : widget.appProvider.books
              .where((b) => b.categoryId == _selectedCategoryFilter)
              .toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDarkBrown,
        foregroundColor: AppColors.textGoldLight,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'إضافة كتاب',
          style: GoogleFonts.readexPro(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _openAddEditDialog(context),
      ),
      body: Column(
        children: [
          // تصفية حسب القسم
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.cardWhite,
            child: Row(
              children: [
                const Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.iconGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'فلترة بالقسم:',
                  style: GoogleFonts.readexPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String?>(
                    value: _selectedCategoryFilter,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('جميع الأقسام'),
                      ),
                      ...widget.appProvider.categories.map((c) {
                        return DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedCategoryFilter = val),
                  ),
                ),
              ],
            ),
          ),

          // قائمة الكتب
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: books.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final b = books[index];
                final cat = widget.appProvider.getCategoryById(b.categoryId);
                return Card(
                  color: AppColors.cardWhite,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.dividerLight),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLightBrown.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.iconGold,
                      ),
                    ),
                    title: Text(
                      b.title,
                      style: GoogleFonts.readexPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'المؤلف: ${b.author} • القسم: ${cat?.name ?? "-"}\n${b.seriesCount} شروحات متوفرة',
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.iconGold,
                            size: 20,
                          ),
                          onPressed: () => _openAddEditDialog(context, book: b),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                          onPressed: () => _confirmDelete(context, b),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. تبويب إدارة الشروحات العلمية (Series Tab)
// ═══════════════════════════════════════════════════════════════════════════
class _SeriesTab extends StatefulWidget {
  final AppProvider appProvider;
  const _SeriesTab({required this.appProvider});

  @override
  State<_SeriesTab> createState() => _SeriesTabState();
}

class _SeriesTabState extends State<_SeriesTab> {
  void _openAddEditDialog(BuildContext context, {SeriesModel? seriesItem}) {
    String selectedCatId =
        seriesItem?.categoryId ??
        (widget.appProvider.categories.isNotEmpty
            ? widget.appProvider.categories.first.id
            : '');

    List<BookModel> availableBooks = widget.appProvider.getBooksByCategory(
      selectedCatId,
    );
    String selectedBookId =
        seriesItem?.bookId ??
        (availableBooks.isNotEmpty ? availableBooks.first.id : '');

    String selectedSheikhId =
        seriesItem?.sheikhId ??
        (widget.appProvider.sheikhs.isNotEmpty
            ? widget.appProvider.sheikhs.first.id
            : '');

    final titleController = TextEditingController(
      text: seriesItem?.title ?? '',
    );
    final pdfUrlController = TextEditingController(
      text: seriesItem?.pdfUrl ?? '',
    );
    final formKey = GlobalKey<FormState>();

    // توليد العنوان تلقائياً إن كان جديداً
    void generateTitle() {
      final book = widget.appProvider.getBookById(selectedBookId);
      final sheikh = widget.appProvider.getSheikhById(selectedSheikhId);
      if (book != null && sheikh != null) {
        titleController.text = 'شرح ${book.title} - ${sheikh.name}';
      }
    }

    if (seriesItem == null && titleController.text.isEmpty) {
      generateTitle();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.scaffoldCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            seriesItem == null ? 'إضافة شرح علمي جديد' : 'تعديل الشرح العلمي',
            style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkBrown,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. اختيار القسم
                  DropdownButtonFormField<String>(
                    initialValue: selectedCatId.isNotEmpty
                        ? selectedCatId
                        : null,
                    decoration: const InputDecoration(
                      labelText: '1. القسم العلمي',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                    items: widget.appProvider.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCatId = val;
                          availableBooks = widget.appProvider
                              .getBooksByCategory(val);
                          selectedBookId = availableBooks.isNotEmpty
                              ? availableBooks.first.id
                              : '';
                          generateTitle();
                        });
                      }
                    },
                    validator: (val) =>
                        val == null ? 'يرجى اختيار القسم' : null,
                  ),
                  const SizedBox(height: 12),

                  // 2. اختيار الكتاب (مفلتر بالقسم)
                  DropdownButtonFormField<String>(
                    initialValue: selectedBookId.isNotEmpty
                        ? selectedBookId
                        : null,
                    decoration: const InputDecoration(
                      labelText: '2. الكتاب أو المتن',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                    items: availableBooks.map((b) {
                      return DropdownMenuItem(
                        value: b.id,
                        child: Text(b.title),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedBookId = val;
                          generateTitle();
                        });
                      }
                    },
                    validator: (val) =>
                        val == null ? 'يرجى اختيار الكتاب' : null,
                  ),
                  const SizedBox(height: 12),

                  // 3. اختيار الشيخ
                  DropdownButtonFormField<String>(
                    initialValue: selectedSheikhId.isNotEmpty
                        ? selectedSheikhId
                        : null,
                    decoration: const InputDecoration(
                      labelText: '3. الشيخ الشارح',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                    items: widget.appProvider.sheikhs.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedSheikhId = val;
                          generateTitle();
                        });
                      }
                    },
                    validator: (val) =>
                        val == null ? 'يرجى اختيار الشيخ' : null,
                  ),
                  const SizedBox(height: 12),

                  // 4. العنوان
                  TextFormField(
                    controller: titleController,
                    style: GoogleFonts.readexPro(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'عنوان الشرح (توليد تلقائي)',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'يرجى إدخال عنوان الشرح'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // 5. رابط ملف الـ PDF (متن/كتاب الشرح اختياري)
                  TextFormField(
                    controller: pdfUrlController,
                    textDirection: TextDirection.ltr,
                    style: GoogleFonts.readexPro(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'رابط ملف الـ PDF للمتن/الكتاب (اختياري)',
                      hintText: 'https://example.com/book.pdf',
                      filled: true,
                      fillColor: AppColors.cardWhite,
                    ),
                  ),
                ],
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkBrown,
                foregroundColor: AppColors.textGoldLight,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final pdfVal = pdfUrlController.text.trim();
                if (seriesItem == null) {
                  final newSeries = SeriesModel(
                    id: 'series_${DateTime.now().millisecondsSinceEpoch}',
                    bookId: selectedBookId,
                    sheikhId: selectedSheikhId,
                    categoryId: selectedCatId,
                    title: titleController.text.trim(),
                    pdfUrl: pdfVal.isNotEmpty ? pdfVal : null,
                  );
                  await widget.appProvider.addSeries(newSeries);
                } else {
                  final updated = seriesItem.copyWith(
                    bookId: selectedBookId,
                    sheikhId: selectedSheikhId,
                    categoryId: selectedCatId,
                    title: titleController.text.trim(),
                    pdfUrl: pdfVal.isNotEmpty ? pdfVal : null,
                  );
                  await widget.appProvider.updateSeries(updated);
                }
              },
              child: Text(
                seriesItem == null ? 'إضافة' : 'حفظ التعديل',
                style: GoogleFonts.readexPro(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SeriesModel series) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف الشرح تتابعياً',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
        content: Text(
          '⚠️ تحذير: حذف الشرح "${series.title}" سيؤدي إلى حذف تتابعي تلقائي لجميع:\n'
          '• كافة الدروس الصوتية المسجلة ضمن هذا الشرح\n'
          '• جميع التفريغات النصية المرتبطة بهذه الدروس\n\n'
          'هل أنت متأكد من الاستمرار في الحذف؟',
          style: GoogleFonts.readexPro(fontSize: 13, height: 1.5),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.appProvider.deleteSeries(series.id);
            },
            child: Text(
              'تأكيد الحذف التتابعي',
              style: GoogleFonts.readexPro(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seriesList = widget.appProvider.series;

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDarkBrown,
        foregroundColor: AppColors.textGoldLight,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'إضافة شرح',
          style: GoogleFonts.readexPro(fontWeight: FontWeight.w600),
        ),
        onPressed: () => _openAddEditDialog(context),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: seriesList.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final s = seriesList[index];
          final book = widget.appProvider.getBookById(s.bookId);
          final sheikh = widget.appProvider.getSheikhById(s.sheikhId);

          return Card(
            color: AppColors.cardWhite,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.dividerLight),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLightBrown.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.library_books_rounded,
                  color: AppColors.iconGold,
                ),
              ),
              title: Text(
                s.title,
                style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'الشارح: ${sheikh?.name ?? "-"} • المتن: ${book?.title ?? "-"}\nعدد الدروس: ${s.lessonsCount}',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.iconGold,
                      size: 20,
                    ),
                    onPressed: () => _openAddEditDialog(context, seriesItem: s),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                    onPressed: () => _confirmDelete(context, s),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. تبويب إدارة الدروس الصوتية والمرئية (Lessons Tab - ميزة Bulk Add)
// ═══════════════════════════════════════════════════════════════════════════
class _LessonsTab extends StatefulWidget {
  final AppProvider appProvider;
  const _LessonsTab({required this.appProvider});

  @override
  State<_LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<_LessonsTab> {
  String? _selectedSeriesId;
  bool _isBulkMode = false;
  bool _singleSendNotification = true;
  bool _bulkSendNotification = true;

  // حقول الإضافة الفردية
  final _singleTitleController = TextEditingController();
  final _singleOrderController = TextEditingController();
  final _singleDurationController = TextEditingController(text: '45:00');
  final _singleAudioUrlController = TextEditingController();
  final _singleVideoUrlController = TextEditingController();
  final _singleTranscriptController = TextEditingController();
  final _singlePdfUrlController = TextEditingController();

  // حقول الإضافة الجماعية Bulk Add
  final _bulkPrefixController = TextEditingController(text: 'الدرس');
  final _bulkTextAreaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.appProvider.series.isNotEmpty) {
      _selectedSeriesId = widget.appProvider.series.first.id;
      _updateDefaultOrder();
    }
  }

  void _updateDefaultOrder() {
    final seriesId = _selectedSeriesId;
    if (seriesId == null) return;
    final lessons = widget.appProvider.getLessonsBySeries(seriesId);
    final nextOrder = lessons.isEmpty
        ? 1
        : (lessons.map((l) => l.order).reduce((a, b) => a > b ? a : b) + 1);
    _singleOrderController.text = nextOrder.toString();
    _singleTitleController.text = 'الدرس $nextOrder';
  }

  @override
  void dispose() {
    _singleTitleController.dispose();
    _singleOrderController.dispose();
    _singleDurationController.dispose();
    _singleAudioUrlController.dispose();
    _singleVideoUrlController.dispose();
    _singleTranscriptController.dispose();
    _singlePdfUrlController.dispose();
    _bulkPrefixController.dispose();
    _bulkTextAreaController.dispose();
    super.dispose();
  }

  Future<void> _handleSingleAdd() async {
    final seriesId = _selectedSeriesId;
    if (seriesId == null) return;
    final title = _singleTitleController.text.trim();
    final audioUrl = _singleAudioUrlController.text.trim();
    final order = int.tryParse(_singleOrderController.text.trim()) ?? 1;

    if (title.isEmpty || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى كتابة عنوان الدرس ورابط MP3',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    final pdfUrl = _singlePdfUrlController.text.trim();
    final newLesson = LessonModel(
      id: 'lesson_${seriesId}_${DateTime.now().millisecondsSinceEpoch}',
      seriesId: seriesId,
      title: title,
      order: order,
      duration: _singleDurationController.text.trim().isNotEmpty
          ? _singleDurationController.text.trim()
          : '45:00',
      audioUrl: audioUrl,
      videoUrl: _singleVideoUrlController.text.trim(),
      transcript: _singleTranscriptController.text.trim(),
      pdfUrl: pdfUrl.isNotEmpty ? pdfUrl : null,
    );

    await widget.appProvider.addLesson(newLesson);
    _singleAudioUrlController.clear();
    _singleVideoUrlController.clear();
    _singleTranscriptController.clear();
    _singlePdfUrlController.clear();
    _updateDefaultOrder();

    if (_singleSendNotification) {
      final series = widget.appProvider.getSeriesById(seriesId);
      final book = series != null
          ? widget.appProvider.getBookById(series.bookId)
          : null;
      final sheikh = series != null
          ? widget.appProvider.getSheikhById(series.sheikhId)
          : null;
      final bookTitle = book?.title ?? series?.title ?? '';
      final sheikhName = sheikh?.name ?? '';

      await widget.appProvider.sendNotification(
        title: 'درس جديد: ${newLesson.title}',
        body: 'تمت إضافة درس جديد في شرح $bookTitle لـ $sheikhName.',
        type: 'lesson',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت إضافة الدرس بنجاح',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: AppColors.primaryDarkBrown,
        ),
      );
    }
  }

  Future<void> _handleBulkAdd() async {
    final seriesId = _selectedSeriesId;
    if (seriesId == null) return;
    final rawText = _bulkTextAreaController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى لصق الروابط الصوتية أولاً',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    final lines = rawText.split('\n');
    final added = await widget.appProvider.bulkAddLessons(
      seriesId: seriesId,
      titlePrefix: _bulkPrefixController.text.trim(),
      rawEntries: lines,
    );

    _bulkTextAreaController.clear();
    _updateDefaultOrder();

    if (added > 0 && _bulkSendNotification) {
      final series = widget.appProvider.getSeriesById(seriesId);
      final book = series != null
          ? widget.appProvider.getBookById(series.bookId)
          : null;
      final sheikh = series != null
          ? widget.appProvider.getSheikhById(series.sheikhId)
          : null;
      final bookTitle = book?.title ?? series?.title ?? '';
      final sheikhName = sheikh?.name ?? '';

      await widget.appProvider.sendNotification(
        title: 'إضافة دروس جديدة',
        body: 'تمت إضافة $added دروس جديدة في شرح $bookTitle لـ $sheikhName.',
        type: 'lesson',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت إضافة $added درساً دفعة واحدة وترتيبها بنجاح!',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: AppColors.primaryDarkBrown,
        ),
      );
    }
  }

  void _confirmDeleteLesson(BuildContext context, LessonModel lesson) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف الدرس',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
        content: Text(
          '⚠️ هل أنت متأكد من حذف الدرس "${lesson.title}"؟\n'
          'سيتم حذف التسجيل الصوتي والتفريغ النصي التابع له وإزالته من سجل المشغل والمحفوظات.',
          style: GoogleFonts.readexPro(fontSize: 13, height: 1.5),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.appProvider.deleteLesson(lesson.id);
              _updateDefaultOrder();
            },
            child: Text(
              'تأكيد الحذف',
              style: GoogleFonts.readexPro(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditLessonDialog(LessonModel lesson) {
    final titleController = TextEditingController(text: lesson.title);
    final orderController = TextEditingController(
      text: lesson.order.toString(),
    );
    final durationController = TextEditingController(text: lesson.duration);
    final audioController = TextEditingController(text: lesson.audioUrl);
    final videoController = TextEditingController(text: lesson.videoUrl);
    final pdfController = TextEditingController(text: lesson.pdfUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تعديل الدرس',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDarkBrown,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الدرس',
                  filled: true,
                  fillColor: AppColors.cardWhite,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الترتيب',
                  filled: true,
                  fillColor: AppColors.cardWhite,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'المدة (مثال: 45:00)',
                  filled: true,
                  fillColor: AppColors.cardWhite,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: audioController,
                decoration: const InputDecoration(
                  labelText: 'رابط الصوت MP3',
                  filled: true,
                  fillColor: AppColors.cardWhite,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: videoController,
                decoration: const InputDecoration(
                  labelText: 'رابط يوتيوب (اختياري)',
                  filled: true,
                  fillColor: AppColors.cardWhite,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: pdfController,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رابط ملف الـ PDF (متن/كتاب اختياري)',
                  hintText: 'https://example.com/lesson.pdf',
                  filled: true,
                  fillColor: AppColors.cardWhite,
                ),
              ),
              if (lesson.hasTranscript) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: Text(
                    'حذف التفريغ النصي فقط',
                    style: GoogleFonts.readexPro(
                      color: Colors.red.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppColors.scaffoldCream,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'حذف التفريغ فقط',
                          style: GoogleFonts.readexPro(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        content: Text(
                          'هل أنت متأكد من حذف التفريغ النصي لدرس "${lesson.title}"؟ سيبقى الدرس الصوتي متاحاً دون حذف.',
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
                              backgroundColor: Colors.red.shade800,
                            ),
                            onPressed: () => Navigator.pop(c, true),
                            child: Text(
                              'حذف التفريغ',
                              style: GoogleFonts.readexPro(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.appProvider.deleteLessonTranscript(
                        lesson.id,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم حذف تفريغ الدرس بنجاح!',
                              style: GoogleFonts.readexPro(),
                            ),
                            backgroundColor: AppColors.primaryDarkBrown,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkBrown,
              foregroundColor: AppColors.textGoldLight,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final pdfVal = pdfController.text.trim();
              final updated = lesson.copyWith(
                title: titleController.text.trim(),
                order:
                    int.tryParse(orderController.text.trim()) ?? lesson.order,
                duration: durationController.text.trim(),
                audioUrl: audioController.text.trim(),
                videoUrl: videoController.text.trim(),
                pdfUrl: pdfVal.isNotEmpty ? pdfVal : null,
              );
              await widget.appProvider.updateLesson(updated);
            },
            child: Text('حفظ', style: GoogleFonts.readexPro()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seriesList = widget.appProvider.series;
    final selectedId = _selectedSeriesId;
    final currentSeriesLessons = selectedId != null
        ? widget.appProvider.getLessonsBySeries(selectedId)
        : <LessonModel>[];

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. اختيار الشرح ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.dividerLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اختر الشرح العلمي للتحكم بدروسه:',
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSeriesId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: AppColors.scaffoldCream,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: seriesList.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSeriesId = val;
                        _updateDefaultOrder();
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── 2. محول النمط: إضافة فردية أم جماعية (Bulk Add) ─────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dividerLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isBulkMode = false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isBulkMode
                              ? AppColors.primaryDarkBrown
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: !_isBulkMode
                                  ? AppColors.textGoldLight
                                  : AppColors.textPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'إضافة درس فردي',
                              style: GoogleFonts.readexPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !_isBulkMode
                                    ? AppColors.textGoldLight
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isBulkMode = true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isBulkMode
                              ? AppColors.primaryDarkBrown
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dynamic_feed_rounded,
                              size: 18,
                              color: _isBulkMode
                                  ? AppColors.textGoldLight
                                  : AppColors.textPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'إضافة جماعية Bulk Add (🌟)',
                              style: GoogleFonts.readexPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isBulkMode
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
            ),

            const SizedBox(height: 14),

            // ── 3. نموذج الإضافة ──────────────────────────────────────────
            if (!_isBulkMode) _buildSingleAddForm() else _buildBulkAddForm(),

            const SizedBox(height: 20),

            // ── 4. جدول/قائمة الدروس الحالية في هذا الشرح ───────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'دروس هذا الشرح (${currentSeriesLessons.length})',
                  style: GoogleFonts.readexPro(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ترتيب تصاعدي',
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (currentSeriesLessons.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.dividerLight),
                ),
                child: Text(
                  'لا توجد دروس مضافة لهذا الشرح حتى الآن.',
                  style: GoogleFonts.readexPro(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentSeriesLessons.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final lesson = currentSeriesLessons[idx];
                  final hasTranscript = lesson.hasTranscript;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.dividerLight),
                    ),
                    child: Row(
                      children: [
                        // دائرة الترتيب
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDarkBrown,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${lesson.order}',
                            style: GoogleFonts.readexPro(
                              color: AppColors.textGoldLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // معلومات الدرس
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                style: GoogleFonts.readexPro(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    lesson.duration,
                                    style: GoogleFonts.readexPro(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasTranscript
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: hasTranscript
                                            ? Colors.green.shade300
                                            : Colors.orange.shade300,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      hasTranscript ? 'مفرغ' : 'غير مفرغ',
                                      style: GoogleFonts.readexPro(
                                        fontSize: 10,
                                        color: hasTranscript
                                            ? Colors.green.shade900
                                            : Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // زر تشغيل تجريبي في المشغل
                        IconButton(
                          tooltip: 'تشغيل المعاينة',
                          icon: const Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppColors.iconGold,
                            size: 26,
                          ),
                          onPressed: () {
                            final series = widget.appProvider.getSeriesById(
                              lesson.seriesId,
                            );
                            if (series != null) {
                              Provider.of<AudioProvider>(
                                context,
                                listen: false,
                              ).loadAndPlayLesson(
                                lesson: lesson,
                                series: series,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'بدأ تشغيل المعاينة: ${lesson.title}',
                                    style: GoogleFonts.readexPro(),
                                  ),
                                  backgroundColor: AppColors.primaryDarkBrown,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),

                        // زر تعديل
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.iconGold,
                            size: 18,
                          ),
                          onPressed: () => _openEditLessonDialog(lesson),
                        ),

                        // زر حذف الدرس
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red.shade400,
                            size: 18,
                          ),
                          onPressed: () =>
                              _confirmDeleteLesson(context, lesson),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── نموذج الإضافة الفردية ────────────────────────────────────────────────
  Widget _buildSingleAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _singleOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    filled: true,
                    fillColor: AppColors.scaffoldCream,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _singleTitleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الدرس (مثال: الدرس 1)',
                    filled: true,
                    fillColor: AppColors.scaffoldCream,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _singleDurationController,
                  decoration: const InputDecoration(
                    labelText: 'المدة (45:00)',
                    filled: true,
                    fillColor: AppColors.scaffoldCream,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _singleAudioUrlController,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رابط ملف الصوت (MP3 URL)',
              hintText: 'https://archive.org/.../01.mp3',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _singleVideoUrlController,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رابط فيديو يوتيوب (اختياري)',
              hintText: 'https://youtube.com/watch?v=...',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _singlePdfUrlController,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رابط ملف الـ PDF (متن/كتاب للدرس اختياري)',
              hintText: 'https://example.com/lesson_booklet.pdf',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _singleTranscriptController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'التفريغ النصي (اختياري - يمكن إضافته لاحقاً)',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: _singleSendNotification,
              title: Text(
                'إرسال إشعار للمستخدمين بهذه الإضافة',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              activeThumbColor: AppColors.iconGold,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _singleSendNotification = val),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _handleSingleAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'إضافة الدرس لهذا الشرح',
              style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkBrown,
              foregroundColor: AppColors.textGoldLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── نموذج الإضافة الجماعية السريعة (Bulk Add) ────────────────────────────
  Widget _buildBulkAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldMuted.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.iconGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'الإضافة الجماعية السريعة (Bulk Import)',
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'الصق هنا عشرات الروابط الصوتية دفعة واحدة. كل رابط في سطر.\nيمكنك كتابة "عنوان الدرس | الرابط" أو الرابط فقط لترتيبها آلياً.',
            style: GoogleFonts.readexPro(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bulkPrefixController,
            decoration: const InputDecoration(
              labelText:
                  'بادئة العنوان التلقائي (عند عدم تحديد عنوان لكل رابط)',
              hintText: 'الدرس',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bulkTextAreaController,
            maxLines: 8,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.readexPro(fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'مساحة لصق الروابط',
              hintText: 'https://archive.org/.../01.mp3\nhttps://archive.org/.../02.mp3\nأو:\nمقدمة الشرح | https://archive.org/.../01.mp3',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: _bulkSendNotification,
              title: Text(
                'إرسال إشعار للمستخدمين بهذه الإضافة',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              activeThumbColor: AppColors.iconGold,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _bulkSendNotification = val),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _handleBulkAdd,
            icon: const Icon(Icons.flash_on_rounded),
            label: Text(
              'استيراد وإضافة جميع الروابط دفعة واحدة',
              style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkBrown,
              foregroundColor: AppColors.textGoldLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. تبويب إدارة التفريغات السريعة (Quick Transcripts Editor)
// ═══════════════════════════════════════════════════════════════════════════
class _TranscriptsTab extends StatefulWidget {
  final AppProvider appProvider;
  const _TranscriptsTab({required this.appProvider});

  @override
  State<_TranscriptsTab> createState() => _TranscriptsTabState();
}

class _TranscriptsTabState extends State<_TranscriptsTab> {
  bool _onlyWithoutTranscript = false;
  String _searchQuery = '';

  Future<bool> _confirmDeleteTranscript(LessonModel lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف تفريغ الدرس',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف التفريغ النصي لدرس "${lesson.title}"؟\n'
          'سيبقى الدرس والملف الصوتي متاحاً للطلاب ولن يتأثر بالحذف.',
          style: GoogleFonts.readexPro(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.readexPro(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'تأكيد حذف التفريغ',
              style: GoogleFonts.readexPro(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.appProvider.deleteLessonTranscript(lesson.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف تفريغ الدرس بنجاح مع بقاء الملف الصوتي!',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: AppColors.primaryDarkBrown,
          ),
        );
      }
      return true;
    }
    return false;
  }

  void _openTranscriptEditor(LessonModel lesson) {
    final controller = TextEditingController(text: lesson.transcript);
    bool sendNotification = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.scaffoldCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'تفريغ: ${lesson.title}',
            style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkBrown,
              fontSize: 15,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اكتب أو الصق التفريغ النصي الكامل للدرس. سيحفظ فوراً ويظهر لجميع الطلاب:',
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: controller,
                  maxLines: 12,
                  style: GoogleFonts.amiri(fontSize: 15, height: 1.8),
                  decoration: const InputDecoration(
                    hintText:
                        'بسم الله الرحمن الرحيم، الحمد لله رب العالمين...',
                    filled: true,
                    fillColor: AppColors.cardWhite,
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: sendNotification,
                  title: Text(
                    'إرسال إشعار للمستخدمين بهذه الإضافة',
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  activeColor: AppColors.primaryDarkBrown,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
                    setDialogState(() {
                      sendNotification = val ?? true;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (lesson.hasTranscript)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade800,
                ),
                onPressed: () async {
                  final deleted = await _confirmDeleteTranscript(lesson);
                  if (deleted && ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: Text(
                  'حذف التفريغ فقط',
                  style: GoogleFonts.readexPro(fontWeight: FontWeight.w600),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: GoogleFonts.readexPro(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkBrown,
                foregroundColor: AppColors.textGoldLight,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await widget.appProvider.updateLessonTranscript(
                  lesson.id,
                  controller.text,
                );
                if (sendNotification && controller.text.trim().isNotEmpty) {
                  final series = widget.appProvider.getSeriesById(
                    lesson.seriesId,
                  );
                  final book = series != null
                      ? widget.appProvider.getBookById(series.bookId)
                      : null;
                  final bookTitle = book?.title ?? series?.title ?? '';

                  await widget.appProvider.sendNotification(
                    title: 'تفريغ نصي جديد',
                    body:
                        'تم توفير التفريغ النصي لـ (${lesson.title}) من شرح $bookTitle.',
                    type: 'transcript',
                  );
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم حفظ التفريغ النصي بنجاح!',
                        style: GoogleFonts.readexPro(),
                      ),
                      backgroundColor: AppColors.primaryDarkBrown,
                    ),
                  );
                }
              },
              child: Text('حفظ التفريغ', style: GoogleFonts.readexPro()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var lessons = widget.appProvider.lessons;

    if (_onlyWithoutTranscript) {
      lessons = lessons.where((l) => !l.hasTranscript).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      lessons = lessons
          .where((l) => l.title.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      body: Column(
        children: [
          // شريط التصفية والبحث
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.cardWhite,
            child: Column(
              children: [
                TextField(
                  style: GoogleFonts.readexPro(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن درس لتحرير تفريغه...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.iconGold,
                    ),
                    filled: true,
                    fillColor: AppColors.scaffoldCream,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Checkbox(
                      value: _onlyWithoutTranscript,
                      activeColor: AppColors.primaryDarkBrown,
                      onChanged: (val) =>
                          setState(() => _onlyWithoutTranscript = val ?? false),
                    ),
                    Text(
                      'عرض الدروس غير المفرغة فقط (${widget.appProvider.lessons.where((l) => !l.hasTranscript).length} درس)',
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // قائمة الدروس والتفريغ
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: lessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final series = widget.appProvider.getSeriesById(
                  lesson.seriesId,
                );
                final hasTranscript = lesson.hasTranscript;

                return Card(
                  color: AppColors.cardWhite,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.dividerLight),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hasTranscript
                            ? Colors.green.shade50
                            : AppColors.goldMuted.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasTranscript
                            ? Icons.check_circle_rounded
                            : Icons.edit_note_rounded,
                        color: hasTranscript
                            ? Colors.green.shade800
                            : AppColors.iconGold,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      lesson.title,
                      style: GoogleFonts.readexPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${series?.title ?? "-"}\n${hasTranscript ? "مفرغ (${lesson.transcript.length} حرف)" : "لم يتم تفريغه بعد"}',
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        color: hasTranscript
                            ? Colors.green.shade800
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasTranscript)
                          IconButton(
                            tooltip: 'حذف التفريغ فقط',
                            icon: Icon(
                              Icons.delete_sweep_rounded,
                              color: Colors.red.shade400,
                              size: 20,
                            ),
                            onPressed: () => _confirmDeleteTranscript(lesson),
                          ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasTranscript
                                ? AppColors.primaryLightBrown.withValues(
                                    alpha: 0.2,
                                  )
                                : AppColors.primaryDarkBrown,
                            foregroundColor: hasTranscript
                                ? AppColors.primaryDarkBrown
                                : AppColors.textGoldLight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: hasTranscript
                                    ? AppColors.goldMuted
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          onPressed: () => _openTranscriptEditor(lesson),
                          child: Text(
                            hasTranscript ? 'تعديل التفريغ' : 'إضافة تفريغ',
                            style: GoogleFonts.readexPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. تبويب إدارة الإشعارات والتحديثات (_NotificationsAndUpdatesTab)
// ═══════════════════════════════════════════════════════════════════════════
class _NotificationsAndUpdatesTab extends StatefulWidget {
  final AppProvider appProvider;
  const _NotificationsAndUpdatesTab({required this.appProvider});

  @override
  State<_NotificationsAndUpdatesTab> createState() =>
      _NotificationsAndUpdatesTabState();
}

class _NotificationsAndUpdatesTabState
    extends State<_NotificationsAndUpdatesTab> {
  // ── البطاقة الأولى: إرسال إشعار مخصص ───────────────────────────────────────
  final _notifTitleController = TextEditingController();
  final _notifBodyController = TextEditingController();
  bool _isSending = false;

  // ── البطاقة الثانية: إدارة تحديثات التطبيق ──────────────────────────────────
  late TextEditingController _versionController;
  late TextEditingController _downloadUrlController;
  late TextEditingController _releaseNotesController;
  late bool _isForceUpdate;
  bool _notifyUsersOnUpdate = true;
  bool _isSavingUpdate = false;

  @override
  void initState() {
    super.initState();
    final updateInfo = widget.appProvider.appUpdateInfo;
    _versionController = TextEditingController(text: updateInfo.latestVersion);
    _downloadUrlController = TextEditingController(
      text: updateInfo.downloadUrl,
    );
    _releaseNotesController = TextEditingController(
      text: updateInfo.releaseNotes,
    );
    _isForceUpdate = updateInfo.isForceUpdate;
  }

  @override
  void dispose() {
    _notifTitleController.dispose();
    _notifBodyController.dispose();
    _versionController.dispose();
    _downloadUrlController.dispose();
    _releaseNotesController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.readexPro()),
        backgroundColor: isError
            ? Colors.red.shade800
            : AppColors.primaryDarkBrown,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSendCustomNotification() async {
    final title = _notifTitleController.text.trim();
    final body = _notifBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _showSnack('يرجى كتابة عنوان الإشعار ونصه بالكامل', isError: true);
      return;
    }

    setState(() => _isSending = true);
    try {
      await widget.appProvider.sendNotification(
        title: title,
        body: body,
        type: 'general',
      );
      _notifTitleController.clear();
      _notifBodyController.clear();
      if (mounted) {
        _showSnack('تم إرسال الإشعار للجميع ونشره بنجاح!');
      }
    } catch (e) {
      if (mounted) _showSnack('حدث خطأ أثناء الإرسال: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleSaveAppUpdate() async {
    final version = _versionController.text.trim();
    final downloadUrl = _downloadUrlController.text.trim();
    final notes = _releaseNotesController.text.trim();

    if (version.isEmpty) {
      _showSnack('يرجى تحديد رقم الإصدار الجديد', isError: true);
      return;
    }

    setState(() => _isSavingUpdate = true);
    try {
      final updatedModel = AppUpdateModel(
        latestVersion: version,
        downloadUrl: downloadUrl,
        releaseNotes: notes,
        isForceUpdate: _isForceUpdate,
      );

      await widget.appProvider.updateAppVersionInfo(
        updatedModel,
        notifyUsers: _notifyUsersOnUpdate,
      );

      if (mounted) {
        _showSnack('تم حفظ ونشر بيانات التحديث الجديد بنجاح!');
      }
    } catch (e) {
      if (mounted) _showSnack('حدث خطأ أثناء حفظ التحديث: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingUpdate = false);
    }
  }

  Future<void> _confirmDeleteNotification(AppNotificationModel notif) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف الإشعار',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف الإشعار "${notif.title}"؟\nسيتم مسحه من سجل الإشعارات وسحابة Firestore.',
          style: GoogleFonts.readexPro(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.readexPro(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'تأكيد الحذف',
              style: GoogleFonts.readexPro(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.appProvider.deleteNotification(notif.id);
      if (mounted) {
        _showSnack('تم حذف الإشعار من السجل بنجاح.');
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sheikh':
        return 'شيخ جديد';
      case 'lesson':
        return 'درس جديد';
      case 'transcript':
        return 'تفريغ نصي';
      case 'update':
        return 'تحديث تطبيق';
      case 'general':
      default:
        return 'إشعار عام';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = widget.appProvider.notifications;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── البطاقة الأولى: إرسال إشعار مخصص للمستخدمين ───────────────
          _buildCustomNotificationCard(),

          const SizedBox(height: 18),

          // ── البطاقة الثانية: إدارة تحديثات التطبيق ───────────────────────
          _buildAppUpdateCard(),

          const SizedBox(height: 18),

          // ── البطاقة الثالثة: سجل الإشعارات المرسلة ──────────────────────
          _buildNotificationsHistoryCard(notifications),
        ],
      ),
    );
  }

  // ── البطاقة الأولى: إرسال إشعار مخصص ───────────────────────────────────────
  Widget _buildCustomNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightBrown.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.iconGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إرسال إشعار مخصص للمستخدمين',
                      style: GoogleFonts.readexPro(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                    Text(
                      'نشر تنبيه أو خبر فوري لجميع مستخدمي تطبيق تسهيل',
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notifTitleController,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'عنوان الإشعار',
              hintText: 'مثال: موعد بدء الدورة العلمية التأصيلية',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notifBodyController,
            maxLines: 3,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'نص الإشعار',
              hintText: 'اكتب نص التنبيه بالتفصيل هنا...',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isSending ? null : _handleSendCustomNotification,
            icon: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textGoldLight,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _isSending ? 'جاري الإرسال...' : 'إرسال الإشعار للجميع الآن',
              style: GoogleFonts.readexPro(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkBrown,
              foregroundColor: AppColors.textGoldLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.goldMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── البطاقة الثانية: إدارة تحديثات التطبيق ──────────────────────────────────
  Widget _buildAppUpdateCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iconGold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.iconGold.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkBrown,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.iconGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة تحديثات التطبيق (نشر إصدار جديد)',
                      style: GoogleFonts.readexPro(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDarkBrown,
                      ),
                    ),
                    Text(
                      'التحكم في التحديثات السحابية والإلزامية ورابط التحميل',
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // شريط عرض إصدار التطبيق الحالي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.scaffoldCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.dividerLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إصدار التطبيق الحالي في هذا البناء:',
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkBrown,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.appProvider.currentAppVersion,
                    style: GoogleFonts.readexPro(
                      color: AppColors.textGoldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // حقل رقم الإصدار الجديد
          TextFormField(
            controller: _versionController,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'رقم الإصدار الجديد (مثال: 1.1.0)',
              hintText: '1.1.0',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 12),

          // حقل رابط التحميل المباشر
          TextFormField(
            controller: _downloadUrlController,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'رابط التحميل المباشر للتحديث (downloadUrl)',
              hintText:
                  'https://example.com/tasheel-latest.apk أو صفحة التحميل',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 12),

          // حقل ملاحظات ومميزات التحديث الجديد
          TextFormField(
            controller: _releaseNotesController,
            maxLines: 3,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'ملاحظات ومميزات التحديث الجديد (releaseNotes)',
              hintText: 'مثال: - إضافة شروحات جديدة\n- تحسين سرعة المشغل الصوتي وتحديث التفريغات',
              filled: true,
              fillColor: AppColors.scaffoldCream,
            ),
          ),
          const SizedBox(height: 12),

          // مفتاح التحديث الإجباري
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: _isForceUpdate,
              title: Text(
                'تحديث إجباري (إلزام المستخدم بالتحديث)',
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'في حال تفعيله، لن يتمكن المستخدم من استخدام التطبيق حتى يحدّث للإصدار الجديد',
                style: GoogleFonts.readexPro(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              activeThumbColor: Colors.red.shade700,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _isForceUpdate = val),
            ),
          ),

          // مفتاح إرسال إشعار تنبيهي
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: _notifyUsersOnUpdate,
              title: Text(
                'إرسال إشعار تنبيهي للمستخدمين بتوفر التحديث',
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'يبعث تلقائياً إشعاراً لجميع الطلاب برابط التحديث والمميزات الجديدة',
                style: GoogleFonts.readexPro(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              activeThumbColor: AppColors.iconGold,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _notifyUsersOnUpdate = val),
            ),
          ),

          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed: _isSavingUpdate ? null : _handleSaveAppUpdate,
            icon: _isSavingUpdate
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textGoldLight,
                    ),
                  )
                : const Icon(Icons.cloud_done_rounded, size: 18),
            label: Text(
              _isSavingUpdate ? 'جاري الحفظ...' : 'حفظ ونشر التحديث',
              style: GoogleFonts.readexPro(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkBrown,
              foregroundColor: AppColors.textGoldLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.goldMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── البطاقة الثالثة: سجل الإشعارات المرسلة ────────────────────────────────
  Widget _buildNotificationsHistoryCard(
    List<AppNotificationModel> notifications,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightBrown.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppColors.iconGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'سجل الإشعارات المرسلة (${notifications.length})',
                    style: GoogleFonts.readexPro(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDarkBrown,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (notifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.scaffoldCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dividerLight),
              ),
              child: Text(
                'لا توجد إشعارات مرسلة حتى الآن.',
                style: GoogleFonts.readexPro(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final notif = notifications[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldCream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dividerLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // أيقونة النوع
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkBrown,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: AppColors.iconGold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // تفاصيل الإشعار
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: GoogleFonts.readexPro(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.primaryDarkBrown,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDarkBrown,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getTypeLabel(notif.type),
                                    style: GoogleFonts.readexPro(
                                      color: AppColors.textGoldLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.body,
                              style: GoogleFonts.readexPro(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(notif.createdAt),
                              style: GoogleFonts.readexPro(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // زر حذف الإشعار
                      IconButton(
                        tooltip: 'حذف الإشعار',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        onPressed: () => _confirmDeleteNotification(notif),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 8. تبويب إدارة عن التطبيق والتواصل والمشاريع (_AboutAppTab)
// ═══════════════════════════════════════════════════════════════════════════
class _AboutAppTab extends StatefulWidget {
  final AppProvider appProvider;
  const _AboutAppTab({required this.appProvider});

  @override
  State<_AboutAppTab> createState() => _AboutAppTabState();
}

class _AboutAppTabState extends State<_AboutAppTab> {
  late TextEditingController _descriptionController;
  late TextEditingController _whatsappController;
  late TextEditingController _telegramController;
  late TextEditingController _facebookController;
  late TextEditingController _youtubeController;
  late TextEditingController _websiteController;
  late TextEditingController _shareDescriptionController;
  late TextEditingController _shareUrlController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final about = widget.appProvider.aboutApp;
    _descriptionController = TextEditingController(text: about.appDescription);
    _whatsappController = TextEditingController(text: about.supportWhatsapp);
    _telegramController = TextEditingController(text: about.telegramUrl);
    _facebookController = TextEditingController(text: about.facebookUrl);
    _youtubeController = TextEditingController(text: about.youtubeUrl);
    _websiteController = TextEditingController(text: about.websiteUrl);
    _shareDescriptionController = TextEditingController(
      text: about.shareDescription,
    );
    _shareUrlController = TextEditingController(text: about.shareUrl);
  }

  @override
  void didUpdateWidget(covariant _AboutAppTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appProvider.aboutApp != widget.appProvider.aboutApp &&
        !_isSaving) {
      final about = widget.appProvider.aboutApp;
      _descriptionController.text = about.appDescription;
      _whatsappController.text = about.supportWhatsapp;
      _telegramController.text = about.telegramUrl;
      _facebookController.text = about.facebookUrl;
      _youtubeController.text = about.youtubeUrl;
      _websiteController.text = about.websiteUrl;
      _shareDescriptionController.text = about.shareDescription;
      _shareUrlController.text = about.shareUrl;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _whatsappController.dispose();
    _telegramController.dispose();
    _facebookController.dispose();
    _youtubeController.dispose();
    _websiteController.dispose();
    _shareDescriptionController.dispose();
    _shareUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await widget.appProvider.updateAboutAppInfo(
        appDescription: _descriptionController.text,
        telegramUrl: _telegramController.text,
        facebookUrl: _facebookController.text,
        youtubeUrl: _youtubeController.text,
        websiteUrl: _websiteController.text,
        supportWhatsapp: _whatsappController.text,
        shareDescription: _shareDescriptionController.text,
        shareUrl: _shareUrlController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ إعدادات التطبيق وروابط التواصل بنجاح!',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: AppColors.primaryDarkBrown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء الحفظ: $e',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openAddEditProjectDialog({OurProjectModel? project}) {
    final titleController = TextEditingController(text: project?.title ?? '');
    final descController = TextEditingController(
      text: project?.description ?? '',
    );
    final urlController = TextEditingController(text: project?.url ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          project == null ? 'إضافة مشروع جديد' : 'تعديل المشروع',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDarkBrown,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  style: GoogleFonts.readexPro(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'عنوان المشروع *',
                    hintText: 'مثال: منصة متون العلمية',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'يرجى إدخال عنوان المشروع'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  style: GoogleFonts.readexPro(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'وصف المشروع *',
                    hintText: 'وصف مختصر لأهداف ومزايا المشروع...',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'يرجى إدخال وصف المشروع'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: urlController,
                  style: GoogleFonts.readexPro(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'رابط المشروع (URL)',
                    hintText: 'https://...',
                  ),
                ),
              ],
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkBrown,
              foregroundColor: AppColors.textGoldLight,
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newProject = OurProjectModel(
                  id:
                      project?.id ??
                      'proj_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  url: urlController.text.trim(),
                );
                Navigator.pop(ctx);
                if (project == null) {
                  await widget.appProvider.addOurProject(newProject);
                } else {
                  await widget.appProvider.updateOurProject(newProject);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        project == null
                            ? 'تمت إضافة المشروع بنجاح!'
                            : 'تم تحديث المشروع بنجاح!',
                        style: GoogleFonts.readexPro(),
                      ),
                      backgroundColor: AppColors.primaryDarkBrown,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              project == null ? 'إضافة' : 'حفظ التعديل',
              style: GoogleFonts.readexPro(),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProject(OurProjectModel project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.scaffoldCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تأكيد حذف المشروع',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade800,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف مشروع "${project.title}"؟ لن يظهر في قسم "من مشاريعنا" في التطبيق.',
          style: GoogleFonts.readexPro(fontSize: 13),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.appProvider.deleteOurProject(project.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم حذف المشروع بنجاح',
                      style: GoogleFonts.readexPro(),
                    ),
                    backgroundColor: AppColors.primaryDarkBrown,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('تأكيد الحذف', style: GoogleFonts.readexPro()),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ?action,
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkBrown,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: AppColors.iconGold, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.dividerLight),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── 1. البطاقة الأولى: نبذة عن التطبيق ──────────────────────────────────────
  Widget _buildCard1AboutDescription() {
    return _buildSectionCard(
      title: 'نبذة عن التطبيق (القسم الأول)',
      icon: Icons.article_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'هذا النص يظهر في أول بطاقة داخل صفحة "عن التطبيق" لشرح رسالة ورؤية التطبيق:',
            style: GoogleFonts.readexPro(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'النص التعريفي لرسالة التطبيق',
              hintText: 'اكتب رسالة ورؤية التطبيق...',
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. البطاقة الثانية: روابط التواصل والدعم الفني ─────────────────────────
  Widget _buildCard2ContactAndSupport() {
    return _buildSectionCard(
      title: 'روابط التواصل والدعم الفني',
      icon: Icons.contact_support_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'رقم واتساب الدعم الفني',
              hintText: '213xxxxxxxxx (بالصيغة الدولية دون مسافات أو علامة +)',
              prefixIcon: Icon(
                Icons.phone_rounded,
                color: AppColors.iconGold,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telegramController,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'رابط قناة تيليجرام',
              hintText: 'https://t.me/...',
              prefixIcon: Icon(
                Icons.send_rounded,
                color: AppColors.iconGold,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _facebookController,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'رابط صفحة فيسبوك',
              hintText: 'https://facebook.com/...',
              prefixIcon: Icon(
                Icons.public_rounded,
                color: AppColors.iconGold,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _youtubeController,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'رابط قناة يوتيوب',
              hintText: 'https://youtube.com/@...',
              prefixIcon: Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.iconGold,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _websiteController,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'رابط الموقع الرسمي',
              hintText: 'https://...',
              prefixIcon: Icon(
                Icons.language_rounded,
                color: AppColors.iconGold,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. البطاقة الثالثة: إعدادات مشاركة التطبيق ──────────────────────────────
  Widget _buildCard3ShareSettings() {
    return _buildSectionCard(
      title: 'إعدادات مشاركة التطبيق',
      icon: Icons.share_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _shareDescriptionController,
            maxLines: 3,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'وصف مشاركة التطبيق',
              hintText: 'اكتب الرسالة التي تظهر عند مشاركة التطبيق...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _shareUrlController,
            style: GoogleFonts.readexPro(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'رابط مشاركة وتحميل التطبيق',
              hintText: 'https://...',
              prefixIcon: Icon(
                Icons.link_rounded,
                color: AppColors.iconGold,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                _isSaving ? 'جاري الحفظ...' : 'حفظ الإعدادات والروابط',
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkBrown,
                foregroundColor: AppColors.textGoldLight,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. البطاقة الرابعة: إدارة قسم من مشاريعنا ──────────────────────────────
  Widget _buildCard4OurProjects() {
    final projects = widget.appProvider.aboutApp.projects;
    return _buildSectionCard(
      title: 'إدارة قسم "من مشاريعنا التقنية"',
      icon: Icons.work_rounded,
      action: ElevatedButton.icon(
        onPressed: () => _openAddEditProjectDialog(),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: Text(
          'إضافة مشروع',
          style: GoogleFonts.readexPro(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDarkBrown,
          foregroundColor: AppColors.textGoldLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'لا توجد مشاريع مضافة حالياً. اضغط "إضافة مشروع" لإدراج مشروع جديد.',
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...projects.map((proj) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dividerLight),
                ),
                child: Row(
                  children: [
                    // أيقونة المشروع وتفاصيله على اليمين
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkBrown.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.iconGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proj.title,
                            style: GoogleFonts.readexPro(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDarkBrown,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            proj.description,
                            style: GoogleFonts.readexPro(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (proj.url.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              proj.url,
                              style: GoogleFonts.readexPro(
                                fontSize: 10,
                                color: AppColors.iconGold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // أزرار التعديل والحذف على اليسار
                    IconButton(
                      tooltip: 'تعديل',
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.iconGold,
                        size: 20,
                      ),
                      onPressed: () => _openAddEditProjectDialog(project: proj),
                    ),
                    IconButton(
                      tooltip: 'حذف',
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                      onPressed: () => _confirmDeleteProject(proj),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard1AboutDescription(),
          _buildCard2ContactAndSupport(),
          _buildCard3ShareSettings(),
          _buildCard4OurProjects(),
        ],
      ),
    );
  }
}
