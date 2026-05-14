import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/em_button.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String? userName;
  const OtpScreen({super.key, required this.phoneNumber, this.userName});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinCtrl = TextEditingController();
  bool _isLoading    = false;
  int  _resendSeconds = 30;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() async {
    _resendSeconds = 30;
    while (_resendSeconds > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendSeconds--);
    }
  }

  Future<void> _verify() async {
    if (_pinCtrl.text.length < 4) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      await Future.delayed(const Duration(seconds: 1)); // Mock API
      if (mounted) {
        context.go('/setup', extra: {'name': widget.userName});
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _error = null; });
    try {
      await ApiService.instance.sendPhoneOtp(widget.phoneNumber);
      _startResendTimer();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;

    final defaultPinTheme = PinTheme(
      width: 60, height: 64,
      textStyle: GoogleFonts.hankenGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onSurface),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primaryContainer, width: 2),
      color: AppColors.surfaceContainerLowest,
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      color: AppColors.primaryFixed,
      border: Border.all(color: AppColors.primaryContainer),
    );

    final maskedPhone = widget.phoneNumber.length > 4
        ? '${widget.phoneNumber.substring(0, widget.phoneNumber.length - 4)}****'
        : widget.phoneNumber;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/signup'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Verify your phone', style: AppTextStyles.headlineLg()),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                  children: [
                    const TextSpan(text: 'We sent a 4-digit code to\n'),
                    TextSpan(
                      text: maskedPhone,
                      style: const TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Center(
                child: Pinput(
                  controller: _pinCtrl,
                  length: 4,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  showCursor: true,
                  onCompleted: (_) => _verify(),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(_error!, style: AppTextStyles.bodySm(color: AppColors.error), textAlign: TextAlign.center),
                ),
              ],

              const SizedBox(height: 40),

              EmButton(label: 'Verify', onPressed: _verify, isLoading: _isLoading),
              const SizedBox(height: 24),

              Center(
                child: _resendSeconds > 0
                    ? RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                          children: [
                            const TextSpan(text: 'Resend code in '),
                            TextSpan(
                              text: '${_resendSeconds}s',
                              style: const TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: _resend,
                        child: Text(
                          'Resend Code',
                          style: AppTextStyles.bodyMd(color: AppColors.primaryContainer).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
