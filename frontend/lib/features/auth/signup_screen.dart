import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/em_button.dart';
import '../../shared/widgets/em_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  int _step = 0; // 0 = account details, 1 = phone/OTP
  String? _selectedGrade;

  static const _grades = [
    'Class 9', 'Class 10', 'Class 11', 'Class 12',
    'Undergraduate', 'Postgraduate',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _next() async {
    if (!_formKey.currentState!.validate()) return;
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/otp');
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
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.go('/login');
            }
          },
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
                // Progress tracker
                Row(
                  children: List.generate(2, (i) {
                    final active = i <= _step;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primaryContainer
                              : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  'Step ${_step + 1} of 2',
                  style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 32),

                if (_step == 0) ...[
                  Text('Create your account', style: AppTextStyles.headlineLg()),
                  const SizedBox(height: 8),
                  Text(
                    'Join thousands of learners on Shiksha Verse.',
                    style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  EmTextField(
                    label: 'Full Name',
                    hint: 'Aarav Singh',
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  EmTextField(
                    label: 'Email',
                    hint: 'you@email.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  EmTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                ] else ...[
                  Text('Almost there!', style: AppTextStyles.headlineLg()),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us about your study level.',
                    style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  Text('Select your grade', style: AppTextStyles.labelMd()),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _grades.map((grade) {
                      final selected = _selectedGrade == grade;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedGrade = grade),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primaryContainer
                                  : AppColors.outlineVariant,
                            ),
                          ),
                          child: Text(
                            grade,
                            style: AppTextStyles.labelMd(
                              color: selected
                                  ? AppColors.onPrimary
                                  : AppColors.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  EmTextField(
                    label: 'Phone Number (for OTP)',
                    hint: '+91 98765 43210',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Phone is required' : null,
                  ),
                ],

                const SizedBox(height: 32),
                EmButton(
                  label: _step == 0 ? 'Continue' : 'Send OTP',
                  onPressed: _next,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                if (_step == 0)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.bodyMd(
                              color: AppColors.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Sign in',
                            style: AppTextStyles.bodyMd(
                                    color: AppColors.primaryContainer)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
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
