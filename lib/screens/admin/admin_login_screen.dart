import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_provider.dart';
import 'admin_dashboard_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// شاشة تسجيل دخول المدير (AdminLoginScreen)
/// ═══════════════════════════════════════════════════════════════════════════
/// البوابة السرية لإدارة محتوى تطبيق تسهيل:
/// - هيدر بني داكن فاخر مع أيقونة القفل الذهبي والزخارف الهندسية.
/// - إدخال البريد الإلكتروني وكلمة المرور مع كشف/إخفاء الرمز السري.
/// - دعم المصادقة الحقيقية عبر FirebaseAuth إن كان مهيأ، أو البيانات التجريبية
///   (admin@tasheel.app / 123456) في وضع الحفظ المحلي.
/// - زر الوصول السريع التجريبي لاختبار ومراجعة جميع أقسام لوحة التحكم فوراً.
/// ═══════════════════════════════════════════════════════════════════════════
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@tasheel.app');
  final _passwordController = TextEditingController(text: '123456');

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AdminDashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    try {
      if (appProvider.isFirebaseConnected) {
        // مصادقة سحابية عبر Firebase Auth
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (mounted) {
            _navigateToDashboard();
          }
        } on FirebaseAuthException catch (e) {
          // إذا لم يكن الحساب موجوداً في Firebase، نسمح ببيانات التجربة للمعاينة
          if (email == 'admin@tasheel.app' && password == '123456') {
            if (mounted) _navigateToDashboard();
            return;
          }
          if (mounted) {
            String message = 'فشل تسجيل الدخول';
            if (e.code == 'user-not-found') {
              message = 'البريد الإلكتروني غير مسجل في قاعدة البيانات';
            } else if (e.code == 'wrong-password') {
              message = 'كلمة المرور غير صحيحة';
            } else if (e.code == 'invalid-email') {
              message = 'صيغة البريد الإلكتروني غير صحيحة';
            }
            _showErrorSnackBar(message);
          }
        }
      } else {
        // الوضع المحلي / التجريبي
        await Future.delayed(const Duration(milliseconds: 300));
        if ((email == 'admin@tasheel.app' && password == '123456') ||
            (email.isNotEmpty && password.length >= 6)) {
          if (mounted) {
            _navigateToDashboard();
          }
        } else {
          if (mounted) {
            _showErrorSnackBar('بيانات الدخول غير صحيحة (التجريبي: admin@tasheel.app / 123456)');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('حدث خطأ أثناء تسجيل الدخول: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.readexPro(color: AppColors.textWhite),
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldCream,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── الهيدر البني الفاخر ─────────────────────────────────────────
            _buildHeader(context, appProvider),

            // ── بطاقة تسجيل الدخول ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // شارة حالة الاتصال
                    _buildConnectionBadge(appProvider),

                    const SizedBox(height: 24),

                    // حقل البريد الإلكتروني
                    _buildEmailField(),

                    const SizedBox(height: 16),

                    // حقل كلمة المرور
                    _buildPasswordField(),

                    const SizedBox(height: 24),

                    // زر تسجيل الدخول الرئيسي
                    _buildLoginButton(),

                    const SizedBox(height: 16),

                    // فاصل أنيق
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.dividerLight)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'أو',
                            style: GoogleFonts.readexPro(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.dividerLight)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // زر الدخول السريع للتجربة
                    _buildQuickDemoButton(),

                    const SizedBox(height: 24),

                    // تلميح الحساب التجريبي
                    _buildDemoHint(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider appProvider) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.primaryDarkBrown,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // شريط الرجوع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'العودة للتطبيق',
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textGoldLight,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightBrown.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.goldMuted.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'لوحة الإدارة',
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    color: AppColors.textGoldLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // أيقونة القفل الذهبي بتأطير دائري فخم
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLightBrown.withValues(alpha: 0.4),
              border: Border.all(color: AppColors.goldLight, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 38,
              color: AppColors.textGoldLight,
            ),
          ),

          const SizedBox(height: 16),

          // العنوان الرئيسي
          Text(
            'بوابة إدارة تطبيق تسهيل',
            style: GoogleFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textGoldLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            'التحكم في المتون والشيوخ والكتب والدروس والتفريغات',
            style: GoogleFonts.readexPro(
              fontSize: 13,
              color: AppColors.textWhite.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge(AppProvider appProvider) {
    final isConnected = appProvider.isFirebaseConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.shade50
            : AppColors.goldMuted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green.shade400 : AppColors.goldMuted,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConnected ? Icons.cloud_done_rounded : Icons.save_rounded,
            size: 18,
            color: isConnected ? Colors.green.shade800 : AppColors.primaryDarkBrown,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isConnected
                  ? 'متصل بالسحابة Firebase (مزامنة فورية)'
                  : 'وضع الحفظ المحلي SharedPreferences (جاهز للعمل)',
              style: GoogleFonts.readexPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isConnected ? Colors.green.shade900 : AppColors.primaryDarkBrown,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'البريد الإلكتروني للمدير',
          style: GoogleFonts.readexPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          style: GoogleFonts.readexPro(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'admin@tasheel.app',
            hintStyle: GoogleFonts.readexPro(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.iconGold),
            filled: true,
            fillColor: AppColors.cardWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.dividerLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.dividerLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.goldMuted, width: 1.8),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال البريد الإلكتروني';
            }
            if (!value.contains('@')) {
              return 'يرجى إدخال بريد إلكتروني صالح';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'كلمة المرور',
          style: GoogleFonts.readexPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textDirection: TextDirection.ltr,
          style: GoogleFonts.readexPro(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: GoogleFonts.readexPro(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.iconGold),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.iconGold,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: AppColors.cardWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.dividerLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.dividerLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.goldMuted, width: 1.8),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال كلمة المرور';
            }
            if (value.length < 6) {
              return 'كلمة المرور يجب أن لا تقل عن 6 أحرف';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDarkBrown,
        foregroundColor: AppColors.textGoldLight,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 2,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.textGoldLight,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تسجيل الدخول إلى لوحة الإدارة',
                  style: GoogleFonts.readexPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickDemoButton() {
    return OutlinedButton(
      onPressed: _navigateToDashboard,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDarkBrown,
        side: const BorderSide(color: AppColors.goldMuted, width: 1.5),
        backgroundColor: AppColors.cardWhite,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_on_rounded, color: AppColors.iconGold, size: 20),
          const SizedBox(width: 8),
          Text(
            'دخول سريع للتجربة (بدون حساب)',
            style: GoogleFonts.readexPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDarkBrown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.iconGold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'بيانات المدير الافتراضية للتجربة:\nالبريد: admin@tasheel.app\nالرمز: 123456\nتتيح إضافة وتعديل المتون والدروس محلياً أو سحابياً.',
              style: GoogleFonts.readexPro(
                fontSize: 12,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
