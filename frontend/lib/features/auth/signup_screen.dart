import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/em_button.dart';
import '../../shared/widgets/em_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading   = false;
  String? _error;

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) => setState(() => _error = msg);

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final phone = _phoneCtrl.text.trim();
      final name  = _nameCtrl.text.trim();
      await Future.delayed(const Duration(seconds: 1)); // Mock API delay
      if (mounted) {
        context.go('/otp', extra: {'phone': phone, 'name': name});
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignInFlow() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) { setState(() => _isLoading = false); return; }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Google sign-in failed');

      await ApiService.instance.googleLogin(idToken);
      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Logo + wordmark
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('SV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Shiksha Verse', style: GoogleFonts.hankenGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  ],
                ),
                const SizedBox(height: 36),
                Text('Create your account', style: AppTextStyles.headlineLg()),
                const SizedBox(height: 8),
                Text('Join millions of learners on Shiksha Verse.', style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 32),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: AppTextStyles.bodySm(color: AppColors.error))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                EmTextField(
                  label: 'Full Name',
                  hint: 'Aarav Singh',
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  validator: (v) => null, // Mock fallback
                ),
                const SizedBox(height: 14),

                EmTextField(
                  label: 'Phone Number',
                  hint: '+91 98765 43210',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (v) {
                    return null; // Mock fallback
                  },
                ),
                const SizedBox(height: 14),

                EmTextField(
                  label: 'Email',
                  hint: 'you@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  validator: (v) {
                    return null; // Mock fallback
                  },
                ),
                const SizedBox(height: 14),

                EmTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant, size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) {
                    return null; // Mock fallback
                  },
                ),
                const SizedBox(height: 28),

                EmButton(label: 'Send OTP', onPressed: _signup, isLoading: _isLoading),
                const SizedBox(height: 20),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or continue with', style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _googleSignInFlow,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: AppColors.outlineVariant),
                    foregroundColor: AppColors.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Text('G', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 18)),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 32),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Already have an account? ', style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text('Sign in', style: AppTextStyles.bodyMd(color: AppColors.primaryContainer).copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
