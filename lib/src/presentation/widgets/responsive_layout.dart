import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 &&
      MediaQuery.sizeOf(context).width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  /// Shared product-grid column count so every product grid (home,
  /// product list, search results) scales consistently on wide/web
  /// viewports instead of each screen hardcoding its own number.
  static int productGridColumns(double width) {
    if (width >= 1400) return 5;
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    return 2;
  }

  /// Horizontal page padding that keeps content flush to the edges on
  /// phones (the normal mobile feel) but caps it to a centered
  /// [maxContentWidth] on wide desktop/web viewports, so text and grids
  /// don't stretch edge-to-edge in a browser window.
  static EdgeInsets pagePadding(
    BuildContext context, {
    double maxContentWidth = 1200,
    double minHorizontal = 16,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width > maxContentWidth
        ? (width - maxContentWidth) / 2
        : minHorizontal;
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) {
      return desktop;
    } else if (width >= 600 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
