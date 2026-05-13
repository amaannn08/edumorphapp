import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum EmButtonVariant { primary, ghost, text }

class EmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EmButtonVariant variant;
  final IconData? leadingIcon;
  final bool isLoading;
  final bool fullWidth;

  const EmButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = EmButtonVariant.primary,
    this.leadingIcon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    switch (variant) {
      case EmButtonVariant.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        );
      case EmButtonVariant.ghost:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: 52,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        );
      case EmButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: Text(label, style: AppTextStyles.labelMd(color: AppColors.primaryContainer)),
        );
    }
  }
}
