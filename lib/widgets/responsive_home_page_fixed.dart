import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ResponsiveHomePage extends StatelessWidget {
  final bool isDarkMode;
  final Widget Function() buildContent;

  const ResponsiveHomePage({
    super.key,
    required this.isDarkMode,
    required this.buildContent,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Mobile form elements stacked vertically
            SizedBox(height: 10.h),
            buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            SizedBox(height: 5.h),
            buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return buildContent();
  }
}

// Simple responsive container that adapts to screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? mobileWidth;
  final double? tabletWidth;
  final double? desktopWidth;
  final double? height;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobileWidth,
    this.tabletWidth,
    this.desktopWidth,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    double width;
    if (isMobile) {
      width = mobileWidth ?? screenWidth * 0.9;
    } else if (isTablet) {
      width = tabletWidth ?? screenWidth * 0.4;
    } else {
      width = desktopWidth ?? 300;
    }

    return SizedBox(width: width, height: height, child: child);
  }
}
