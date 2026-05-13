import 'package:flutter/material.dart';
import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/em_button.dart';
import '../../shared/widgets/em_progress_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    final user = mockUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A0F8A), Color(0xFF4F46E5)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          user.name[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.name,
                        style: AppTextStyles.headlineSm(color: Colors.white),
                      ),
                      Text(
                        user.username,
                        style:
                            AppTextStyles.labelMd(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Stats Cards ───────────────────────────────────
                  Row(
                    children: [
                      _ProfileStat(
                          value: '${user.streakDays}', label: 'Day\nStreak', emoji: '🔥'),
                      _ProfileStat(
                          value: '${user.xp}', label: 'Total\nXP', emoji: '⚡'),
                      _ProfileStat(
                          value: '#${user.rank}', label: 'Global\nRank', emoji: '🏆'),
                      _ProfileStat(
                          value: '${mockCourses.length}',
                          label: 'Courses\nEnrolled', emoji: '📚'),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Weekly Activity ───────────────────────────────
                  Text('Weekly Activity', style: AppTextStyles.headlineSm()),
                  const SizedBox(height: 14),
                  _WeeklyActivityBar(),
                  const SizedBox(height: 28),

                  // ── Overall Progress ──────────────────────────────
                  Text('Overall Progress', style: AppTextStyles.headlineSm()),
                  const SizedBox(height: 14),
                  EmProgressBar(
                    value: 0.64,
                    label: 'Course completion avg.',
                    showPercent: true,
                  ),
                  const SizedBox(height: 20),

                  // ── My Subjects ───────────────────────────────────
                  Text('My Subjects', style: AppTextStyles.headlineSm()),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.subjects
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.chipBackground,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                s,
                                style: AppTextStyles.labelMd(
                                    color: AppColors.chipText),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 28),

                  // ── Recent Courses ────────────────────────────────
                  Text('Recent Courses', style: AppTextStyles.headlineSm()),
                  const SizedBox(height: 14),
                  ...mockCourses.take(3).map(
                        (c) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.play_circle_outline_rounded,
                                    color: AppColors.primaryContainer),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(c.title,
                                        style: AppTextStyles.labelMd(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    EmProgressBar(value: c.progress),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(c.progress * 100).toInt()}%',
                                style: AppTextStyles.labelMd(
                                    color: AppColors.primaryContainer),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 28),

                  // ── Sign Out ──────────────────────────────────────
                  EmButton(
                    label: 'Sign Out',
                    variant: EmButtonVariant.ghost,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;

  const _ProfileStat(
      {required this.value, required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.headlineSm(color: AppColors.primaryContainer)),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption()),
        ],
      ),
    );
  }
}

class _WeeklyActivityBar extends StatelessWidget {
  final List<double> _activity = const [0.4, 0.8, 0.6, 1.0, 0.5, 0.3, 0.7];
  final List<String> _days = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        7,
        (i) => Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 400 + i * 60),
              width: 36,
              height: 80 * _activity[i],
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.primary, AppColors.primaryContainer],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(_days[i], style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
