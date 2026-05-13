import 'package:flutter/material.dart';
import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/em_progress_bar.dart';

class VideoPlayerScreen extends StatefulWidget {
  final CourseModel? course;
  const VideoPlayerScreen({super.key, this.course});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _isPlaying = false;
  double _progress = 0.38;
  int _selectedTab = 0;
  bool _isBookmarked = false;

  late CourseModel _course;

  @override
  void initState() {
    super.initState();
    _course = widget.course ?? mockCourses[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Video Player ─────────────────────────────────────
            Container(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    // Thumbnail
                    Image.network(
                      _course.thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF0D0D1A),
                        child: const Center(
                          child: Icon(Icons.play_circle_fill_rounded,
                              color: Colors.white54, size: 64),
                        ),
                      ),
                    ),
                    Container(color: Colors.black.withValues(alpha: 0.3)),

                    // Controls overlay
                    Column(
                      children: [
                        // Top bar
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 20),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _isBookmarked = !_isBookmarked),
                                child: Icon(
                                  _isBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: _isBookmarked
                                      ? AppColors.primaryFixedDim
                                      : Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.more_vert_rounded,
                                  color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                        const Spacer(),

                        // Center play
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isPlaying = !_isPlaying),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryContainer
                                      .withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Bottom progress
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _formatTime(_progress * 3600),
                                    style: AppTextStyles.labelSm(
                                        color: Colors.white),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _course.duration,
                                    style: AppTextStyles.labelSm(
                                        color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onHorizontalDragUpdate: (d) {
                                  final box = context.findRenderObject()
                                      as RenderBox;
                                  setState(() {
                                    _progress = (_progress +
                                            d.delta.dx / box.size.width)
                                        .clamp(0.0, 1.0);
                                  });
                                },
                                child: EmProgressBar(value: _progress),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Info ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.chipBackground,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _course.subject,
                          style: AppTextStyles.labelSm(
                              color: AppColors.chipText),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.share_outlined,
                          color: AppColors.onSurfaceVariant, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_course.title,
                      style: AppTextStyles.headlineSm(), maxLines: 2),
                  const SizedBox(height: 4),
                  Text(_course.instructor,
                      style:
                          AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 16),

                  // Tabs
                  Row(
                    children: ['Overview', 'Transcript', 'Resources']
                        .asMap()
                        .entries
                        .map((e) => GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedTab = e.key),
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(right: 24, bottom: 8),
                                child: Column(
                                  children: [
                                    Text(
                                      e.value,
                                      style: AppTextStyles.labelMd(
                                        color: _selectedTab == e.key
                                            ? AppColors.primaryContainer
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (_selectedTab == e.key)
                                      Container(
                                        height: 2,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),

            // ── Tab Content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _selectedTab == 0
                    ? _OverviewTab(course: _course)
                    : _selectedTab == 1
                        ? _TranscriptTab()
                        : _ResourcesTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _OverviewTab extends StatelessWidget {
  final CourseModel course;
  const _OverviewTab({required this.course});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this lecture', style: AppTextStyles.labelMd()),
        const SizedBox(height: 8),
        Text(
          'This lecture covers core principles of ${course.subject} with clear visual examples and step-by-step explanations. Perfect for exam preparation and conceptual clarity.',
          style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Text('What you\'ll learn', style: AppTextStyles.labelMd()),
        const SizedBox(height: 12),
        ...['Core theoretical framework', 'Practical problem-solving techniques',
            'Common exam patterns', 'Real-world applications']
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 10, color: AppColors.primaryContainer),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item,
                            style: AppTextStyles.bodyMd(
                                color: AppColors.onSurface)),
                      ),
                    ],
                  ),
                )),
      ],
    );
  }
}

class _TranscriptTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lines = [
      '0:00  Welcome to today\'s lecture. We\'ll begin by understanding...',
      '0:45  The fundamental principle here is that energy cannot be...',
      '1:30  Let\'s look at a real example. Imagine a closed system...',
      '2:15  This is where most students get confused. Remember...',
      '3:00  The formula we need to apply is F = ma, where...',
      '4:10  Great, so now we\'ve covered the first law. Moving to...',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.split('  ')[0],
                      style: AppTextStyles.labelSm(
                          color: AppColors.primaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        line.split('  ')[1],
                        style: AppTextStyles.bodyMd(
                            color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final resources = [
      {'icon': Icons.picture_as_pdf_rounded, 'name': 'Lecture Notes.pdf', 'size': '2.4 MB'},
      {'icon': Icons.quiz_rounded, 'name': 'Practice Problems.pdf', 'size': '1.1 MB'},
      {'icon': Icons.link_rounded, 'name': 'Reference: NCERT Chapter 7', 'size': 'Link'},
    ];
    return Column(
      children: resources
          .map((r) => Container(
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(r['icon'] as IconData,
                          color: AppColors.primaryContainer, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['name'] as String,
                              style: AppTextStyles.labelMd()),
                          Text(r['size'] as String,
                              style: AppTextStyles.caption()),
                        ],
                      ),
                    ),
                    const Icon(Icons.download_rounded,
                        color: AppColors.primaryContainer, size: 20),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
