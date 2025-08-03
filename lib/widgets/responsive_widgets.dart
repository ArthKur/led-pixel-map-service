import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'responsive_layout.dart';

class ResponsiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isDarkMode;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final double? customWidth;
  final Widget? suffixIcon;

  const ResponsiveTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isDarkMode,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.customWidth,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final width = customWidth ?? ResponsiveDimensions.inputWidth(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: ResponsiveDimensions.fontSize(14),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: ResponsiveDimensions.fontSize(14),
          ),
          border: InputBorder.none,
          contentPadding: ResponsiveDimensions.padding(all: 3),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isDarkMode;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isSecondary;

  const ResponsiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.isDarkMode,
    this.backgroundColor,
    this.textColor,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveDimensions.buttonSize(context);

    return SizedBox(
      width: buttonSize.width,
      height: buttonSize.height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ??
              (isSecondary
                  ? (isDarkMode ? Colors.grey[700] : Colors.grey[200])
                  : (isDarkMode ? Colors.blue[700] : Colors.blue)),
          foregroundColor:
              textColor ??
              (isSecondary
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: ResponsiveDimensions.fontSize(12),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const ResponsiveCard({
    super.key,
    required this.child,
    required this.isDarkMode,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ResponsiveDimensions.containerWidth(context),
      margin: margin ?? ResponsiveDimensions.padding(all: 2),
      padding: padding ?? ResponsiveDimensions.padding(all: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isDarkMode;
  final List<Widget>? actions;
  final Widget? leading;

  const ResponsiveAppBar({
    super.key,
    required this.title,
    required this.isDarkMode,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveDimensions.fontSize(18),
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[300],
      elevation: 0,
      actions: actions,
      leading: leading,
      iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(7.h);
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width?.w,
      height: height?.h,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: border,
      ),
      child: child,
    );
  }
}

class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool wrapOnMobile;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrapOnMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    if (wrapOnMobile && ResponsiveDimensions.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (child) => Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: child,
              ),
            )
            .toList(),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

class ResponsiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;

  const ResponsiveSizedBox({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width?.w, height: height?.h);
  }
}
