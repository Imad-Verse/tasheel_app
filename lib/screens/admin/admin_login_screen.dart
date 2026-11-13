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
/// البوابة الرسمية الآمنة لإدارة محتوى تطبيق تسهيل:
/// - هيدر بني داكن فاخر مع أيقونة القفل الذهبي والزخارف الهندسية.
/// - إدخال البريد الإلكتروني وكلمة المرور في حقول فارغة تماماً مع كشف/إخفاء الرمز.
/// - مصادقة حصرية وفعلية عبر Firebase Authentication مع رسائل تنبيه عربية دقيقة.
/// ═══════════════════════════════════════════════════════════════════════════
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (!appProvider.isFirebaseConnected) {
      _showErrorSnackBar(
        'خدمة Firebase غير متصلة حالياً. يلزم توفر اتصال بالإنترنت لتسجيل دخول المدير.',
      );
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // مصادقة سحابية حصرية عبر FirebaseAuth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        _navigateToDashboard();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'فشل تسجيل الدخول';
        if (e.code == 'user-not-found') {
          message = 'البريد الإلكتروني غير مسجل في قاعدة البيانات';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = 'كلمة المرور غير صحيحة أو بيانات الدخول غير متطابقة';
        } else if (e.code == 'invalid-email') {
          message = 'صيغة البريد الإلكتروني غير صحيحة';
        } else if (e.code == 'user-disabled') {
          message = 'تم تعطيل هذا الحساب من قِبل إدارة النظام';
        } else if (e.code == 'too-many-requests') {
          message = 'تم حظر المحاولات مؤقتاً لكثرة المحاولات الخاطئة. يرجى المحاولة لاحقاً.';
        } else if (e.code == 'network-request-failed') {
          message = 'فشل الاتصال بالشبكة. يرجى التحقق من اتصال الإنترنت.';
        } else {
          message = 'تعذر تسجيل الدخول: ${e.message ?? e.code}';
        }
        _showErrorSnackBar(message);
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

                    // حقل البريد الإلكتروني (فارغ تماماً)
                    _buildEmailField(),

                    const SizedBox(height: 16),

                    // حقل كلمة المرور (فارغ تماماً)
                    _buildPasswordField(),

                    const SizedBox(height: 26),

                    // زر تسجيل الدخول الرئيسي
                    _buildLoginButton(),
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
            'تسجيل الدخول المعتمد للتحكم بالمحتوى العلمي والمزامنة السحابية',
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
            isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 18,
            color: isConnected ? Colors.green.shade800 : AppColors.primaryDarkBrown,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isConnected
                  ? 'بوابة المصادقة: متصل بـ Firebase Authentication'
                  : 'بوابة المصادقة: يلزم توفر اتصال بـ Firebase',
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
            hintText: 'name@example.com',
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
}
