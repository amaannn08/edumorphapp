import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/em_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final List<String> _subjects = [
    'Physics', 'Mathematics', 'Chemistry', 'Biology',
    'History', 'Geography', 'English', 'Economics',
    'Computer Science', 'Political Science',
  ];
  final Set<String> _selected = {};
  bool _isLoading = false;

  static const _minSelect = 2;

  void _finish() async {
    if (_selected.length < _minSelect) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least $_minSelect subjects'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Header
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppColors.primaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text('Pick your subjects', style: AppTextStyles.headlineLg()),
              const SizedBox(height: 8),
              Text(
                'Choose what you\'re studying — we\'ll tailor your feed.',
                style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                '${_selected.length} selected (minimum $_minSelect)',
                style: AppTextStyles.labelMd(
                  color: _selected.length >= _minSelect
                      ? AppColors.primaryContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Subject chips
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _subjects.map((subject) {
                      final isSelected = _selected.contains(subject);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selected.remove(subject);
                          } else {
                            _selected.add(subject);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryContainer
                                  : AppColors.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.check_rounded,
                                      size: 16, color: AppColors.onPrimary),
                                ),
                              Text(
                                subject,
                                style: AppTextStyles.labelMd(
                                  color: isSelected
                                      ? AppColors.onPrimary
                                      : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              EmButton(
                label: 'Start Learning →',
                onPressed: _finish,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
