import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final bool showBackground;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.backgroundColor,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/meetup_logo.png',
      width: width ?? 40,
      height: height ?? 40,
      fit: BoxFit.contain,
    );

    if (showBackground) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: logo,
      );
    }

    return logo;
  }
}

