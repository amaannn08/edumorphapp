import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/em_progress_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSubject = 'All';
  final _scrollCtrl = ScrollController();

  List<CourseModel> get _filtered => _selectedSubject == 'All'
      ? mockCourses
      : mockCourses.where((c) => c.subject == _selectedSubject).toList();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.surfaceContainerLowest,
            elevation: 0,
            scrolledUnderElevation: 1,
            automaticallyImplyLeading: false,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad - 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'SV',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Shiksha Verse',
                    style: AppTextStyles.headlineSm(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.onSurface),
                    onPressed: () {},
                    tooltip: 'Notifications',
                  ),
                  GestureDetector(
                    onTap: () => context.go('/home/profile'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryFixed,
                      child: Text(
                        mockUser.name[0],
                        style: AppTextStyles.labelMd(color: AppColors.primaryContainer),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Greeting ──────────────────────────────────────
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.headlineMd(),
                      children: [
                        const TextSpan(text: 'Good evening, '),
                        TextSpan(
                          text: mockUser.name.split(' ').first,
                          style: const TextStyle(color: AppColors.primaryContainer),
                        ),
                        const TextSpan(text: ' 👋'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You\'re on a ${mockUser.streakDays}-day streak — keep going!',
                    style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // ── Stats Row ─────────────────────────────────────
                  Row(
                    children: [
                      _StatCard(
                        label: 'Streak',
                        value: '${mockUser.streakDays}d 🔥',
                        color: const Color(0xFFFFF3E0),
                        textColor: const Color(0xFFE65100),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'XP',
                        value: '${mockUser.xp}',
                        color: AppColors.primaryFixed,
                        textColor: AppColors.primaryContainer,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Rank',
                        value: '#${mockUser.rank}',
                        color: const Color(0xFFF3E5F5),
                        textColor: const Color(0xFF7B1FA2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Search Bar ────────────────────────────────────
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Search lectures, topics...',
                          style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Continue Learning ─────────────────────────────
                  if (mockCourses.any((c) => c.progress > 0 && c.progress < 1)) ...[
                    Text('Continue Learning', style: AppTextStyles.headlineSm()),
                    const SizedBox(height: 16),
                    _ContinueLearningCard(
                      course: mockCourses.firstWhere(
                          (c) => c.progress > 0 && c.progress < 1),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Subject Filter ────────────────────────────────
                  Text('Explore Courses', style: AppTextStyles.headlineSm()),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // Subject filter chips (horizontal scroll)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: pad),
                itemCount: subjectTags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final tag = subjectTags[i];
                  final sel = _selectedSubject == tag;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSubject = tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: sel ? AppColors.primaryContainer : AppColors.outlineVariant,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.labelMd(
                          color: sel ? AppColors.onPrimary : AppColors.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Course Grid / List ─────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: context.isMobile
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CourseCard(course: _filtered[i]),
                      ),
                      childCount: _filtered.length,
                    ),
                  )
                : SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: context.gridColumns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _CourseCard(course: _filtered[i]),
                      childCount: _filtered.length,
                    ),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.headlineSm(color: textColor),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSm(color: textColor.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final CourseModel course;
  const _ContinueLearningCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Image.network(
              course.thumbnailUrl,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 110,
                height: 110,
                color: AppColors.primaryFixed,
                child: const Icon(Icons.play_circle_fill_rounded,
                    color: AppColors.primaryContainer, size: 36),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SubjectChip(subject: course.subject),
                  const SizedBox(height: 6),
                  Text(
                    course.title,
                    style: AppTextStyles.labelMd(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  EmProgressBar(
                    value: course.progress,
                    label: 'Progress',
                    showPercent: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Stack(
              children: [
                Image.network(
                  course.thumbnailUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppColors.primaryFixed,
                    child: const Center(
                      child: Icon(Icons.play_circle_fill_rounded,
                          color: AppColors.primaryContainer, size: 48),
                    ),
                  ),
                ),
                // Duration badge
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.duration,
                      style: AppTextStyles.labelSm(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SubjectChip(subject: course.subject),
                    const Spacer(),
                    _DifficultyBadge(difficulty: course.difficulty),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  course.title,
                  style: AppTextStyles.labelMd(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  course.instructor,
                  style: AppTextStyles.caption(),
                ),
                const SizedBox(height: 8),
                Text(
                  '${course.lessons} lessons',
                  style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant),
                ),
                if (course.progress > 0) ...[
                  const SizedBox(height: 10),
                  EmProgressBar(value: course.progress, showPercent: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String subject;
  const _SubjectChip({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        subject,
        style: AppTextStyles.labelSm(color: AppColors.chipText),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  Color get _bg => difficulty == 'Advanced'
      ? const Color(0xFFFFEBEE)
      : difficulty == 'Intermediate'
          ? const Color(0xFFFFF8E1)
          : const Color(0xFFE8F5E9);

  Color get _fg => difficulty == 'Advanced'
      ? const Color(0xFFD32F2F)
      : difficulty == 'Intermediate'
          ? const Color(0xFFF57F17)
          : const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        difficulty,
        style: AppTextStyles.labelSm(color: _fg),
      ),
    );
  }
}
