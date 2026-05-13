import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  final Set<int> _liked = {1}; // s2 pre-liked

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical shorts feed
          PageView.builder(
            controller: _pageCtrl,
            scrollDirection: Axis.vertical,
            itemCount: mockShorts.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final short = mockShorts[i];
              final isLiked = _liked.contains(i);
              return _ShortCard(
                short: short,
                isLiked: isLiked,
                onLike: () => setState(() {
                  if (isLiked) {
                    _liked.remove(i);
                  } else {
                    _liked.add(i);
                  }
                }),
              );
            },
          ),

          // Top gradient + title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Shorts',
                        style: AppTextStyles.headlineMd(color: Colors.white),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '60 sec',
                              style: AppTextStyles.labelMd(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scroll indicator dots (right side)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  mockShorts.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    width: 4,
                    height: _currentPage == i ? 20 : 6,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.primaryContainer
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortCard extends StatelessWidget {
  final ShortModel short;
  final bool isLiked;
  final VoidCallback onLike;

  const _ShortCard({
    required this.short,
    required this.isLiked,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image (video placeholder)
        Image.network(
          short.thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A0F8A), Color(0xFF4F46E5)],
              ),
            ),
          ),
        ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.3, 0.65, 1.0],
            ),
          ),
        ),

        // Play button overlay
        const Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white54,
            size: 72,
          ),
        ),

        // Bottom info + actions
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 72, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      short.subject,
                      style: AppTextStyles.labelSm(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    short.title,
                    style: AppTextStyles.headlineSm(color: Colors.white),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        short.instructor,
                        style: AppTextStyles.labelSm(color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.remove_red_eye_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatViews(short.views),
                        style: AppTextStyles.labelSm(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right-side action buttons
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              // Like
              _ActionBtn(
                icon: isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: _formatViews(
                    short.views ~/ 4 + (isLiked ? 1 : 0)),
                color: isLiked ? Colors.red : Colors.white,
                onTap: onLike,
              ),
              const SizedBox(height: 20),
              // Share
              _ActionBtn(
                icon: Icons.reply_rounded,
                label: 'Share',
                color: Colors.white,
                onTap: () {},
              ),
              const SizedBox(height: 20),
              // Save
              _ActionBtn(
                icon: Icons.bookmark_border_rounded,
                label: 'Save',
                color: Colors.white,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatViews(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSm(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
