import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Academic Clarity Typography
/// Headlines: Hanken Grotesk — sharp, contemporary
/// Body/Labels: Inter — exceptional readability
class AppTextStyles {
  AppTextStyles._();

  // ── Display ─────────────────────────────────────────────
  static TextStyle display({Color color = AppColors.onSurface}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.02 * 48,
        color: color,
      );

  // ── Headlines ───────────────────────────────────────────
  static TextStyle headlineLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.01 * 32,
        color: color,
      );

  static TextStyle headlineMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle headlineSm({Color color = AppColors.onSurface}) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  // ── Body ────────────────────────────────────────────────
  static TextStyle bodyLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle bodyMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle bodySm({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  // ── Labels ──────────────────────────────────────────────
  static TextStyle labelMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.01 * 14,
        color: color,
      );

  static TextStyle labelSm({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.01 * 12,
        color: color,
      );

  static TextStyle caption({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );
}
