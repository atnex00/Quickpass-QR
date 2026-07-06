import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickpassColors {
  static const Color primary = Color(0xFF1E40AF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF00288E);
  static const Color onPrimaryContainer = Color(0xFFA8B8FF);
  static const Color secondary = Color(0xFF2563EB);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF316BF3);
  static const Color onSecondaryContainer = Color(0xFFFEFCFF);
  static const Color tertiary = Color(0xFF5854A5);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color background = Color(0xFFFBF8FF);
  static const Color onBackground = Color(0xFF1A1B22);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1B22);
  static const Color surfaceContainerLowest = Color(0xFFFBF8FF);
  static const Color surfaceContainerLow = Color(0xFFF4F2FC);
  static const Color surfaceContainer = Color(0xFFF2F0F9);
  static const Color surfaceContainerHigh = Color(0xFFECEBF5);
  static const Color surfaceVariant = Color(0xFFEEEDF7);
  static const Color onSurfaceVariant = Color(0xFF444653);
  static const Color outline = Color(0xFF757684);
  static const Color outlineVariant = Color(0xFFC4C5D5);
  static const Color success = Color(0xFF16A34A);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccessContainer = Color(0xFF064E3B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color surfaceNavy = Color(0xFF0F172A);
  static const Color neutralGray = Color(0xFF64748B);

  static const Color darkBackground = Color(0xFF121414);
  static const Color darkOnBackground = Color(0xFFE2E2E2);
  static const Color darkSurface = Color(0xFF1E2020);
  static const Color darkOnSurface = Color(0xFFE2E2E2);
  static const Color darkPrimary = Color(0xFFFFD700);
  static const Color darkOnPrimary = Color(0xFF3A3000);
  static const Color darkPrimaryContainer = Color(0xFFFFD700);
  static const Color darkOnPrimaryContainer = Color(0xFF705E00);
  static const Color darkSecondary = Color(0xFFC8C6C5);
  static const Color darkOnSecondary = Color(0xFF313030);
  static const Color darkSurfaceVariant = Color(0xFF333535);
  static const Color darkOnSurfaceVariant = Color(0xFFD0C6AB);
  static const Color darkOutline = Color(0xFF999077);
  static const Color darkOutlineVariant = Color(0xFF4D4732);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);
  static const Color darkSuccess = Color(0xFF6EE7B7);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkSurfaceContainerLowest = Color(0xFF232525);
  static const Color darkSurfaceContainer = Color(0xFF2A2C2C);
  static const Color darkSurfaceContainerHigh = Color(0xFF2E3030);

  // QR-specific
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
        primaryContainer: QuickpassColors.primary,
        onPrimaryContainer: QuickpassColors.onPrimaryContainer,
        secondary: QuickpassColors.secondary,
        onSecondary: QuickpassColors.onSecondary,
        secondaryContainer: QuickpassColors.secondary,
        onSecondaryContainer: QuickpassColors.onSecondaryContainer,
        tertiary: QuickpassColors.tertiary,
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: QuickpassColors.outlineVariant),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: QuickpassColors.primary,
          foregroundColor: QuickpassColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QuickpassColors.primary,
          side: const BorderSide(color: QuickpassColors.outline),
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
          borderSide: const BorderSide(color: QuickpassColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: QuickpassColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: QuickpassColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: QuickpassColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: QuickpassColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: QuickpassColors.onSurfaceVariant),
        hintStyle: TextStyle(color: QuickpassColors.onSurfaceVariant.withValues(alpha: 0.6)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: QuickpassColors.surface,
        indicatorColor: QuickpassColors.primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: QuickpassColors.primary);
          }
          return const IconThemeData(color: QuickpassColors.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: QuickpassColors.primary);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: QuickpassColors.onSurfaceVariant);
        }),
        elevation: 0,
        height: 65,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: QuickpassColors.surface,
        selectedItemColor: QuickpassColors.primary,
        unselectedItemColor: QuickpassColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
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
        primaryContainer: QuickpassColors.darkPrimary,
        onPrimaryContainer: QuickpassColors.darkOnPrimaryContainer,
        secondary: QuickpassColors.darkSecondary,
        onSecondary: QuickpassColors.darkOnSecondary,
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: QuickpassColors.darkOutlineVariant.withValues(alpha: 0.4)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: QuickpassColors.darkPrimary,
          foregroundColor: QuickpassColors.darkOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QuickpassColors.darkPrimary,
          side: const BorderSide(color: QuickpassColors.darkPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: QuickpassColors.darkSurface,
        indicatorColor: QuickpassColors.darkPrimary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: QuickpassColors.darkPrimary);
          }
          return const IconThemeData(color: QuickpassColors.darkOnSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: QuickpassColors.darkPrimary);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: QuickpassColors.darkOnSurfaceVariant);
        }),
        elevation: 0,
        height: 65,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: QuickpassColors.darkOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: QuickpassColors.darkOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: QuickpassColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: QuickpassColors.darkError),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: QuickpassColors.darkOnSurfaceVariant),
      ),

      dividerTheme: DividerThemeData(
        color: QuickpassColors.darkOutlineVariant.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: QuickpassColors.darkPrimary,
        foregroundColor: QuickpassColors.darkOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
