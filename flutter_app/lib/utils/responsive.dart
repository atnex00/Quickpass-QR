import 'package:flutter/material.dart';

const double _designWidth = 375;
const double tabletBreakpoint = 600;
const double desktopBreakpoint = 900;

enum ScreenType { phone, tablet, desktop }

/// Returns the screen type based on width breakpoints.
ScreenType getScreenType(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= desktopBreakpoint) return ScreenType.desktop;
  if (w >= tabletBreakpoint) return ScreenType.tablet;
  return ScreenType.phone;
}

/// Returns a value based on the current screen type.
T adaptiveValue<T>(BuildContext context,
    {required T phone, T? tablet, T? desktop}) {
  switch (getScreenType(context)) {
    case ScreenType.desktop:
      return desktop ?? tablet ?? phone;
    case ScreenType.tablet:
      return tablet ?? phone;
    case ScreenType.phone:
      return phone;
  }
}

/// Scales a value based on screen height (not width), preventing overflow on short screens.
double responsiveHeight(BuildContext context, double size) {
  final h = MediaQuery.of(context).size.height;
  return size * (h / 812).clamp(0.75, 1.15);
}

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
  final scaled = base *
      (MediaQuery.of(context).size.width / _designWidth).clamp(0.85, 1.2);
  return MediaQuery.textScalerOf(context)
      .scale(scaled)
      .clamp(scaled * 0.85, scaled * 1.3);
}

EdgeInsets responsivePadding(BuildContext context,
    {double horizontal = 16, double vertical = 16}) {
  final scale =
      (MediaQuery.of(context).size.width / _designWidth).clamp(0.8, 1.2);
  return EdgeInsets.symmetric(
    horizontal: horizontal * scale,
    vertical: vertical * scale,
  );
}

double responsiveSize(BuildContext context, double base) {
  return base *
      (MediaQuery.of(context).size.width / _designWidth).clamp(0.8, 1.2);
}
