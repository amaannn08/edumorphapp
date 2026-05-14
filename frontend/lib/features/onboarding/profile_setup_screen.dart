import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/em_button.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String? userName;
  const ProfileSetupScreen({super.key, this.userName});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _grades = [
    'Class 5', 'Class 6', 'Class 7', 'Class 8',
    'Class 9', 'Class 10', 'Class 11', 'Class 12',
    'Undergraduate', 'Postgraduate',
  ];

  static const _languages = ['English', 'Hindi', 'Tamil', 'Telugu', 'Kannada', 'Bengali', 'Marathi'];

  static const _careers = [
    'IIT-JEE', 'NEET', 'UPSC', 'SSC', 'CLAT', 'NDA', 'CA Foundation', 'Coding & Tech',
  ];

  String? _selectedGrade;
  String? _selectedLanguage;
  final Set<String> _selectedCareers  = {};
  final Set<String> _selectedSubjects = {};
  bool   _isLoading = false;
  String? _error;

  static const _subjects = [
    'Physics', 'Mathematics', 'Chemistry', 'Biology',
    'History', 'Geography', 'English', 'Economics',
    'Computer Science', 'Political Science',
  ];

  int get _step {
    if (_selectedGrade == null) return 0;
    if (_selectedLanguage == null) return 1;
    if (_selectedCareers.isEmpty) return 2;
    return 3;
  }

  Future<void> _finish() async {
    if (_selectedSubjects.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select at least 2 subjects'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.instance.put('/profile', body: {
        'grade': _selectedGrade,
        'language': _selectedLanguage,
        'career_interests': _selectedCareers.toList(),
        'subjects': _selectedSubjects.toList(),
      });
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.school_outlined, color: AppColors.primaryContainer, size: 28),
              ),
              const SizedBox(height: 20),
              if (widget.userName != null) ...[
                Text('Hey ${widget.userName!.split(' ').first}! 👋', style: AppTextStyles.headlineSm()),
                const SizedBox(height: 4),
              ],
              Text('Set up your profile', style: AppTextStyles.headlineLg()),
              const SizedBox(height: 8),
              Text("We'll personalise your learning experience.", style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 24),

              // Step progress dots
              Row(
                children: List.generate(4, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 6),
                  width: i == _step ? 24 : 8, height: 8,
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.primaryContainer : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                )),
              ),
              const SizedBox(height: 28),

              if (_error != null) ...[
                Text(_error!, style: AppTextStyles.bodySm(color: AppColors.error)),
                const SizedBox(height: 12),
              ],

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Step 0: Grade ─────────────────────────────────────
                      Text('What class are you in?', style: AppTextStyles.labelMd()),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _grades.map((g) {
                          final sel = _selectedGrade == g;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedGrade = g),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: sel ? AppColors.primaryContainer : AppColors.outlineVariant),
                              ),
                              child: Text(g, style: AppTextStyles.labelMd(color: sel ? AppColors.onPrimary : AppColors.onSurface)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // ── Step 1: Language ──────────────────────────────────
                      Text('Preferred learning language', style: AppTextStyles.labelMd()),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _languages.map((l) {
                          final sel = _selectedLanguage == l;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedLanguage = l),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: sel ? AppColors.primaryContainer : AppColors.outlineVariant),
                              ),
                              child: Text(l, style: AppTextStyles.labelMd(color: sel ? AppColors.onPrimary : AppColors.onSurface)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // ── Step 2: Career ────────────────────────────────────
                      Text('Career goals', style: AppTextStyles.labelMd()),
                      const SizedBox(height: 4),
                      Text('Select all that apply', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _careers.map((c) {
                          final sel = _selectedCareers.contains(c);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (sel) { _selectedCareers.remove(c); } else { _selectedCareers.add(c); }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: sel ? AppColors.primaryContainer : AppColors.outlineVariant),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (sel) const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.check_rounded, size: 14, color: AppColors.primaryContainer),
                                  ),
                                  Text(c, style: AppTextStyles.labelMd(
                                    color: sel ? AppColors.primaryContainer : AppColors.onSurface,
                                  )),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // ── Step 3: Subjects ──────────────────────────────────
                      Row(
                        children: [
                          Text('Pick your subjects', style: AppTextStyles.labelMd()),
                          const Spacer(),
                          Text('${_selectedSubjects.length} selected (min 2)',
                              style: AppTextStyles.labelSm(
                                color: _selectedSubjects.length >= 2
                                    ? AppColors.primaryContainer
                                    : AppColors.onSurfaceVariant,
                              )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _subjects.map((s) {
                          final sel = _selectedSubjects.contains(s);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (sel) { _selectedSubjects.remove(s); } else { _selectedSubjects.add(s); }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: sel ? AppColors.primaryContainer : AppColors.outlineVariant),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (sel) const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary),
                                  ),
                                  Text(s, style: AppTextStyles.labelMd(color: sel ? AppColors.onPrimary : AppColors.onSurface)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              EmButton(label: 'Start Learning →', onPressed: _finish, isLoading: _isLoading),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
