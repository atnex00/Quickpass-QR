import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickpassColors {
  static const Color primary = Color(0xFF1E40AF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDBE4FF);
  static const Color onPrimaryContainer = Color(0xFF001B3E);
  static const Color secondary = Color(0xFF2563EB);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDAE2FF);
  static const Color onSecondaryContainer = Color(0xFF001B3E);
  static const Color tertiary = Color(0xFF5854A5);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFE6DEFF);
  static const Color onTertiaryContainer = Color(0xFF130A41);
  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
  static const Color background = Color(0xFFFBF8FF);
  static const Color onBackground = Color(0xFF1A1B22);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1B22);
  static const Color surfaceVariant = Color(0xFFF0F0F8);
  static const Color onSurfaceVariant = Color(0xFF49465E);
  static const Color outline = Color(0xFF7B7890);
  static const Color outlineVariant = Color(0xFFC8C5D6);
  static const Color success = Color(0xFF10B981);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccessContainer = Color(0xFF064E3B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF78350F);

  // Dark
  static const Color darkPrimary = Color(0xFFB8C4FF);
  static const Color darkOnPrimary = Color(0xFF002F65);
  static const Color darkPrimaryContainer = Color(0xFF003B7E);
  static const Color darkOnPrimaryContainer = Color(0xFFDBE4FF);
  static const Color darkSecondary = Color(0xFFB4C5FF);
  static const Color darkOnSecondary = Color(0xFF002F65);
  static const Color darkSecondaryContainer = Color(0xFF003B7E);
  static const Color darkOnSecondaryContainer = Color(0xFFDAE2FF);
  static const Color darkTertiary = Color(0xFFCABEFF);
  static const Color darkOnTertiary = Color(0xFF282058);
  static const Color darkTertiaryContainer = Color(0xFF3F3A7E);
  static const Color darkOnTertiaryContainer = Color(0xFFE6DEFF);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkOnBackground = Color(0xFFE4E1F0);
  static const Color darkSurface = Color(0xFF1A1B2D);
  static const Color darkOnSurface = Color(0xFFE4E1F0);
  static const Color darkSurfaceVariant = Color(0xFF252641);
  static const Color darkOnSurfaceVariant = Color(0xFFC8C5D6);
  static const Color darkOutline = Color(0xFF918FA6);
  static const Color darkOutlineVariant = Color(0xFF49465E);
  static const Color darkSuccess = Color(0xFF6EE7B7);
  static const Color darkOnSuccess = Color(0xFF064E3B);
  static const Color darkSuccessContainer = Color(0xFF065F46);
  static const Color darkOnSuccessContainer = Color(0xFFD1FAE5);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkOnWarning = Color(0xFF78350F);
  static const Color darkWarningContainer = Color(0xFF92400E);
  static const Color darkOnWarningContainer = Color(0xFFFEF3C7);

  // QR colors
  static const Color qrOut = Color(0xFF2563EB);
  static const Color qrIn = Color(0xFF16A34A);
}

class QuickpassTheme {
  static ThemeData get light {
    final textTheme = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: QuickpassColors.primary,
        onPrimary: QuickpassColors.onPrimary,
        primaryContainer: QuickpassColors.primaryContainer,
        onPrimaryContainer: QuickpassColors.onPrimaryContainer,
        secondary: QuickpassColors.secondary,
        onSecondary: QuickpassColors.onSecondary,
        secondaryContainer: QuickpassColors.secondaryContainer,
        onSecondaryContainer: QuickpassColors.onSecondaryContainer,
        tertiary: QuickpassColors.tertiary,
        onTertiary: QuickpassColors.onTertiary,
        tertiaryContainer: QuickpassColors.tertiaryContainer,
        onTertiaryContainer: QuickpassColors.onTertiaryContainer,
        error: QuickpassColors.error,
        onError: QuickpassColors.onError,
        errorContainer: QuickpassColors.errorContainer,
        onErrorContainer: QuickpassColors.onErrorContainer,
        surface: QuickpassColors.surface,
        onSurface: QuickpassColors.onSurface,
        surfaceContainerHighest: QuickpassColors.surfaceVariant,
        onSurfaceVariant: QuickpassColors.onSurfaceVariant,
        outline: QuickpassColors.outline,
        outlineVariant: QuickpassColors.outlineVariant,
      ),
      scaffoldBackgroundColor: QuickpassColors.background,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: QuickpassColors.primary,
        foregroundColor: QuickpassColors.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: QuickpassColors.onPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: QuickpassColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: QuickpassColors.outlineVariant.withValues(alpha: 0.6)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QuickpassColors.primary,
          foregroundColor: QuickpassColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: QuickpassColors.primary,
          foregroundColor: QuickpassColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QuickpassColors.primary,
          side: BorderSide(color: QuickpassColors.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QuickpassColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: QuickpassColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QuickpassColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QuickpassColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QuickpassColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QuickpassColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QuickpassColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: QuickpassColors.onSurfaceVariant),
        hintStyle: TextStyle(color: QuickpassColors.onSurfaceVariant.withValues(alpha: 0.6)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: QuickpassColors.surface,
        indicatorColor: QuickpassColors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: QuickpassColors.primary);
          }
          return IconThemeData(color: QuickpassColors.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: QuickpassColors.primary);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: QuickpassColors.onSurfaceVariant);
        }),
        elevation: 2,
        height: 65,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: QuickpassColors.surface,
        selectedItemColor: QuickpassColors.primary,
        unselectedItemColor: QuickpassColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: GoogleFonts.inter(fontSize: 13),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        actionTextColor: QuickpassColors.onPrimary,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: QuickpassColors.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: QuickpassColors.primary,
        foregroundColor: QuickpassColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: QuickpassColors.outlineVariant),
          ),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: QuickpassColors.darkPrimary,
        onPrimary: QuickpassColors.darkOnPrimary,
        primaryContainer: QuickpassColors.darkPrimaryContainer,
        onPrimaryContainer: QuickpassColors.darkOnPrimaryContainer,
        secondary: QuickpassColors.darkSecondary,
        onSecondary: QuickpassColors.darkOnSecondary,
        secondaryContainer: QuickpassColors.darkSecondaryContainer,
        onSecondaryContainer: QuickpassColors.darkOnSecondaryContainer,
        tertiary: QuickpassColors.darkTertiary,
        onTertiary: QuickpassColors.darkOnTertiary,
        tertiaryContainer: QuickpassColors.darkTertiaryContainer,
        onTertiaryContainer: QuickpassColors.darkOnTertiaryContainer,
        error: QuickpassColors.darkError,
        onError: QuickpassColors.darkOnError,
        errorContainer: QuickpassColors.darkErrorContainer,
        onErrorContainer: QuickpassColors.darkOnErrorContainer,
        surface: QuickpassColors.darkSurface,
        onSurface: QuickpassColors.darkOnSurface,
        surfaceContainerHighest: QuickpassColors.darkSurfaceVariant,
        onSurfaceVariant: QuickpassColors.darkOnSurfaceVariant,
        outline: QuickpassColors.darkOutline,
        outlineVariant: QuickpassColors.darkOutlineVariant,
      ),
      scaffoldBackgroundColor: QuickpassColors.darkBackground,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: QuickpassColors.darkSurface,
        foregroundColor: QuickpassColors.darkOnSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: QuickpassColors.darkOnSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: QuickpassColors.darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: QuickpassColors.darkOutlineVariant.withValues(alpha: 0.4)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: QuickpassColors.darkSurface,
        indicatorColor: QuickpassColors.darkPrimaryContainer,
        elevation: 2,
        height: 65,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: QuickpassColors.darkSurface,
        selectedItemColor: QuickpassColors.darkPrimary,
        unselectedItemColor: QuickpassColors.darkOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: QuickpassColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QuickpassColors.darkOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QuickpassColors.darkOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QuickpassColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QuickpassColors.darkError),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      dividerTheme: DividerThemeData(
        color: QuickpassColors.darkOutlineVariant.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
