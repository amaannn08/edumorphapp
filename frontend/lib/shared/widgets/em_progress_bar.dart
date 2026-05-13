import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Thick 8px indigo progress bar with rounded ends
/// Matches Stitch spec: "Use a thick 8px track height with fully rounded ends.
/// The filled portion should utilize a subtle horizontal gradient."
class EmProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final String? label;
  final bool showPercent;

  const EmProgressBar({
    super.key,
    required this.value,
    this.label,
    this.showPercent = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercent)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(label!, style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)),
              if (showPercent)
                Text('$pct%', style: AppTextStyles.labelSm(color: AppColors.primaryContainer)),
            ],
          ),
        if (label != null || showPercent) const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Track
                Container(
                  height: 8,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                // Fill with gradient
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: constraints.maxWidth * value.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryContainer],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
