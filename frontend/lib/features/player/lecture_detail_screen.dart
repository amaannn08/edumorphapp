import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';

class LectureDetailScreen extends StatefulWidget {
  final String courseId;
  const LectureDetailScreen({super.key, required this.courseId});

  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends State<LectureDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _course = {};
  List<Map<String, dynamic>> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    setState(() => _isLoading = true);
    try {
      final r = await ApiService.instance.get('/courses/${widget.courseId}');
      final data = r['data'] as Map<String, dynamic>;
      setState(() {
        _course  = data;
        _lessons = (data['lessons'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      });
    } catch (_) {
      setState(() {
        _course = {'title': 'Physics Mechanics', 'subject': 'Physics', 'instructor_name': 'H.C. Verma', 'progress': 45};
        _lessons = [
          {'id': 'l1', 'title': 'Kinematics', 'duration_minutes': 15, 'progress_pct': 100, 'is_bookmarked': true, 'video_url': 'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'},
          {'id': 'l2', 'title': 'Newton\'s Laws', 'duration_minutes': 25, 'progress_pct': 0, 'is_bookmarked': false, 'video_url': 'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'},
        ];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleBookmark(String lessonId, bool isBookmarked) async {
    try {
      if (isBookmarked) {
        await ApiService.instance.delete('/courses/${widget.courseId}/bookmark');
      } else {
        await ApiService.instance.post('/courses/${widget.courseId}/bookmark', body: {'lesson_id': lessonId});
      }
      _loadCourse();
    } catch (_) {}
  }

  void _openDoubtDialog() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask a Doubt', style: AppTextStyles.headlineSm()),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Type your doubt here...', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer, foregroundColor: Colors.white),
                onPressed: () async {
                  if (ctrl.text.length >= 10) {
                    final messenger = ScaffoldMessenger.of(context);
                    await ApiService.instance.post('/courses/doubts', body: {
                      'question': ctrl.text,
                      'course_id': widget.courseId,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Doubt submitted! Check your Vault.')),
                    );
                  }
                },
                child: const Text('Submit Doubt'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
      );
    }

    final pad      = context.pagePadding;
    final subject  = _course['subject'] as String? ?? '';
    final progress = (_course['progress'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Hero thumbnail ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _course['thumbnail_url'] != null
                        ? Image.network(_course['thumbnail_url'] as String, fit: BoxFit.cover)
                        : Container(color: AppColors.surfaceContainerLow),
                  ),
                  // Gradient overlay
                  Positioned.fill(child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                    ),
                  )),
                  // Back button
                  Positioned(
                    top: 12, left: 12,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  // Play button
                  Positioned.fill(
                    child: Center(
                      child: GestureDetector(
                        onTap: _lessons.isNotEmpty
                            ? () => context.push('/player/${_lessons[0]['id']}', extra: _lessons[0])
                            : null,
                        child: Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.primaryContainer.withValues(alpha: 0.4), blurRadius: 16)]),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Course info ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.chipBackground, borderRadius: BorderRadius.circular(999)),
                          child: Text(subject, style: AppTextStyles.labelSm(color: AppColors.chipText)),
                        ),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.share_outlined, color: AppColors.onSurfaceVariant, size: 20), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.help_outline_rounded, color: AppColors.onSurfaceVariant, size: 20), onPressed: _openDoubtDialog),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_course['title'] as String? ?? '', style: AppTextStyles.headlineSm(), maxLines: 2),
                    const SizedBox(height: 4),
                    Text(_course['instructor_name'] as String? ?? '', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    if (progress > 0) ...[
                      Row(
                        children: [
                          Expanded(child: Stack(children: [
                            Container(height: 4, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(999))),
                            FractionallySizedBox(
                              widthFactor: (progress / 100).clamp(0.0, 1.0),
                              child: Container(height: 4, decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(999))),
                            ),
                          ])),
                          const SizedBox(width: 8),
                          Text('${progress.toInt()}%', style: AppTextStyles.labelSm(color: AppColors.primaryContainer)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('${_lessons.length} Lessons', style: AppTextStyles.labelMd()),
                    ),
                  ],
                ),
              ),
            ),

            // ── Lesson list ──────────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final lesson = _lessons[i];
                  final isBookmarked = lesson['is_bookmarked'] as bool? ?? false;
                  final lessonProgress = (lesson['progress_pct'] as num?)?.toDouble() ?? 0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                    child: GestureDetector(
                      onTap: () => context.push('/player/${lesson['id']}', extra: lesson),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: lessonProgress > 0 ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                lessonProgress >= 100 ? Icons.check_rounded : Icons.play_arrow_rounded,
                                color: lessonProgress > 0 ? Colors.white : AppColors.onSurfaceVariant,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(lesson['title'] as String? ?? '', style: AppTextStyles.labelMd()),
                                  Text(
                                    '${lesson['duration_minutes'] ?? '?'} min',
                                    style: AppTextStyles.caption(),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: isBookmarked ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () => _toggleBookmark(lesson['id'] as String, isBookmarked),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _lessons.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
