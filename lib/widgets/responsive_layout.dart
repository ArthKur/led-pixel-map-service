import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sizer/sizer.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (context) => mobile,
      tablet: (context) => tablet,
      desktop: (context) => desktop,
    );
  }
}

// Helper class for responsive dimensions
class ResponsiveDimensions {
  static double width(double percentage) => percentage.w;
  static double height(double percentage) => percentage.h;
  static double fontSize(double size) => size.sp;

  // Responsive padding and margins
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: left ?? horizontal ?? all ?? 0,
      right: right ?? horizontal ?? all ?? 0,
      top: top ?? vertical ?? all ?? 0,
      bottom: bottom ?? vertical ?? all ?? 0,
    );
  }

  // Responsive SizedBox
  static SizedBox box({double? width, double? height}) {
    return SizedBox(width: width, height: height);
  }

  // Get screen type
  static DeviceScreenType getScreenType(BuildContext context) {
    return getDeviceType(MediaQuery.of(context).size);
  }

  // Check if mobile
  static bool isMobile(BuildContext context) {
    return getScreenType(context) == DeviceScreenType.mobile;
  }

  // Check if tablet
  static bool isTablet(BuildContext context) {
    return getScreenType(context) == DeviceScreenType.tablet;
  }

  // Check if desktop
  static bool isDesktop(BuildContext context) {
    return getScreenType(context) == DeviceScreenType.desktop;
  }

  // Responsive container width - Fixed sizing for better control
  static double containerWidth(BuildContext context) {
    final screenType = getScreenType(context);
    final screenWidth = MediaQuery.of(context).size.width;

    switch (screenType) {
      case DeviceScreenType.mobile:
        return screenWidth * 0.9;
      case DeviceScreenType.tablet:
        return screenWidth * 0.8;
      case DeviceScreenType.desktop:
        return screenWidth > 1600 ? 850 : screenWidth * 0.4;
      default:
        return screenWidth * 0.9;
    }
  }

  // Responsive input field width - Fixed sizing for consistency
  static double inputWidth(BuildContext context) {
    final screenType = getScreenType(context);
    final screenWidth = MediaQuery.of(context).size.width;

    switch (screenType) {
      case DeviceScreenType.mobile:
        return screenWidth * 0.9;
      case DeviceScreenType.tablet:
        return 300;
      case DeviceScreenType.desktop:
        return 250;
      default:
        return screenWidth * 0.9;
    }
  }

  // Responsive button size - Fixed sizing for consistency
  static Size buttonSize(BuildContext context) {
    final screenType = getScreenType(context);

    switch (screenType) {
      case DeviceScreenType.mobile:
        return Size(35.w, 50);
      case DeviceScreenType.tablet:
        return const Size(180, 45);
      case DeviceScreenType.desktop:
        return const Size(160, 40);
      default:
        return Size(35.w, 50);
    }
  }

  // Responsive columns for grid layouts
  static int getColumnsCount(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case DeviceScreenType.mobile:
        return 1;
      case DeviceScreenType.tablet:
        return 2;
      case DeviceScreenType.desktop:
        return 3;
      default:
        return 1;
    }
  }
}

// Responsive grid widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveDimensions.getColumnsCount(context);

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        return SizedBox(
          width: (100 / columns).w - (spacing * (columns - 1) / columns),
          child: child,
        );
      }).toList(),
    );
  }
}
