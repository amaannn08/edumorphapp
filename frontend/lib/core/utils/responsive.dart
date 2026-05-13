import 'package:flutter/material.dart';

/// Responsive breakpoints matching Stitch design spec
/// Mobile: < 600  |  Tablet: 600–1024  |  Desktop: > 1024
class Responsive {
  Responsive._();

  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;
  static const double _maxContainer = 1280;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= _mobileBreakpoint && w < _tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _tabletBreakpoint;

  /// Horizontal page padding (16px mobile, 24px tablet, 40px desktop)
  static double pagePadding(BuildContext context) {
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 24;
    return 40;
  }

  /// Max content width (constrains layout on wide screens)
  static double maxWidth(BuildContext context) => _maxContainer;

  /// Grid columns for course card grids
  static int gridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  /// Section vertical gap
  static double sectionGap(BuildContext context) => isMobile(context) ? 40 : 64;
}

/// Extension for convenience
extension ResponsiveContext on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  double get pagePadding => Responsive.pagePadding(this);
  int get gridColumns => Responsive.gridColumns(this);
  double get sectionGap => Responsive.sectionGap(this);
}
