import 'package:flutter/material.dart';

const double _designWidth = 375;

double scaleWidth(BuildContext context, double size) {
  return size * (MediaQuery.of(context).size.width / _designWidth);
}

bool isSmallScreen(BuildContext context) {
  return MediaQuery.of(context).size.width < 360;
}

bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.width >= 600;
}

double responsiveFontSize(BuildContext context, double base) {
  final scaled = base * (MediaQuery.of(context).size.width / _designWidth).clamp(0.85, 1.2);
  return MediaQuery.textScalerOf(context).scale(scaled).clamp(scaled * 0.85, scaled * 1.3);
}

EdgeInsets responsivePadding(BuildContext context,
    {double horizontal = 16, double vertical = 16}) {
  final scale = (MediaQuery.of(context).size.width / _designWidth).clamp(0.8, 1.2);
  return EdgeInsets.symmetric(
    horizontal: horizontal * scale,
    vertical: vertical * scale,
  );
}

double responsiveSize(BuildContext context, double base) {
  return base * (MediaQuery.of(context).size.width / _designWidth).clamp(0.8, 1.2);
}
