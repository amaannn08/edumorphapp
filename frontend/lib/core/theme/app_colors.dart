import 'package:flutter/material.dart';

/// Academic Clarity Design System — Shiksha Verse
/// Source: Google Stitch "Remix of Remix of Minimalist Lecture Reels"
class AppColors {
  AppColors._();

  // Primary — Electric Indigo
  static const Color primary = Color(0xFF3525CD);
  static const Color primaryContainer = Color(0xFF4F46E5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFDAD7FF);
  static const Color primaryFixed = Color(0xFFE2DFFF);
  static const Color primaryFixedDim = Color(0xFFC3C0FF);
  static const Color inversePrimary = Color(0xFFC3C0FF);

  // Secondary — Deep Slate
  static const Color secondary = Color(0xFF565E74);
  static const Color secondaryContainer = Color(0xFFDAE2FD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF5C647A);

  // Tertiary — Neutral Gray
  static const Color tertiary = Color(0xFF46494B);
  static const Color tertiaryContainer = Color(0xFF5E6163);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFDADCDE);

  // Surface & Background
  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF0B1C30);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF464555);
  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);

  // Outline
  static const Color outline = Color(0xFF777587);
  static const Color outlineVariant = Color(0xFFC7C4D8);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Misc
  static const Color surfaceTint = Color(0xFF4D44E3);
  static const Color surfaceVariant = Color(0xFFD3E4FE);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic shorthand
  static const Color accent = primaryContainer; // #4F46E5 — use for CTAs
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color chipBackground = Color(0xFFEEF2FF);
  static const Color chipText = primaryContainer;
}
