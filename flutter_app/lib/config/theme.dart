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

class StatusColors extends ThemeExtension<StatusColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;

  const StatusColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
  });

  @override
  StatusColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
  }) {
    return StatusColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }

  static const StatusColors light = StatusColors(
    success: QuickpassColors.success,
    onSuccess: QuickpassColors.onSuccess,
    successContainer: QuickpassColors.successContainer,
    onSuccessContainer: QuickpassColors.onSuccessContainer,
    warning: QuickpassColors.warning,
    onWarning: QuickpassColors.onWarning,
  );

  static const StatusColors dark = StatusColors(
    success: QuickpassColors.darkSuccess,
    onSuccess: Color(0xFF003320),
    successContainer: Color(0xFF064E3B),
    onSuccessContainer: QuickpassColors.darkSuccess,
    warning: QuickpassColors.darkWarning,
    onWarning: Color(0xFF3A2E00),
  );
}

class AppColors extends ThemeExtension<AppColors> {
  final Color primaryBlue;
  final Color neutralGray;
  final Color qrOut;
  final Color qrIn;
  final Color surfaceNavy;

  const AppColors({
    required this.primaryBlue,
    required this.neutralGray,
    required this.qrOut,
    required this.qrIn,
    required this.surfaceNavy,
  });

  @override
  AppColors copyWith({
    Color? primaryBlue,
    Color? neutralGray,
    Color? qrOut,
    Color? qrIn,
    Color? surfaceNavy,
  }) {
    return AppColors(
      primaryBlue: primaryBlue ?? this.primaryBlue,
      neutralGray: neutralGray ?? this.neutralGray,
      qrOut: qrOut ?? this.qrOut,
      qrIn: qrIn ?? this.qrIn,
      surfaceNavy: surfaceNavy ?? this.surfaceNavy,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      neutralGray: Color.lerp(neutralGray, other.neutralGray, t)!,
      qrOut: Color.lerp(qrOut, other.qrOut, t)!,
      qrIn: Color.lerp(qrIn, other.qrIn, t)!,
      surfaceNavy: Color.lerp(surfaceNavy, other.surfaceNavy, t)!,
    );
  }

  static const AppColors light = AppColors(
    primaryBlue: QuickpassColors.primary,
    neutralGray: QuickpassColors.neutralGray,
    qrOut: QuickpassColors.qrOut,
    qrIn: QuickpassColors.qrIn,
    surfaceNavy: QuickpassColors.surfaceNavy,
  );

  static const AppColors dark = AppColors(
    primaryBlue: Color(0xFFB8C4FF),
    neutralGray: Color(0xFF94A3B8),
    qrOut: Color(0xFF60A5FA),
    qrIn: QuickpassColors.darkSuccess,
    surfaceNavy: Color(0xFF1E293B),
  );
}

extension QuickpassColorsX on BuildContext {
  ColorScheme get _cs => Theme.of(this).colorScheme;
  StatusColors get _st => Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
  AppColors get _ap => Theme.of(this).extension<AppColors>() ?? AppColors.light;

  Color get surface => _cs.surface;
  Color get onSurface => _cs.onSurface;
  Color get surfaceContainerLowest => _cs.surfaceContainerLowest;
  Color get surfaceContainerLow => _cs.surfaceContainerLow;
  Color get surfaceContainer => _cs.surfaceContainer;
  Color get surfaceContainerHigh => _cs.surfaceContainerHigh;
  Color get surfaceVariant => _cs.surfaceContainerHighest;
  Color get onSurfaceVariant => _cs.onSurfaceVariant;
  Color get outline => _cs.outline;
  Color get outlineVariant => _cs.outlineVariant;
  Color get error => _cs.error;
  Color get onError => _cs.onError;
  Color get errorContainer => _cs.errorContainer;
  Color get onErrorContainer => _cs.onErrorContainer;
  Color get primary => _cs.primary;
  Color get onPrimary => _cs.onPrimary;
  Color get primaryContainer => _cs.primaryContainer;
  Color get onPrimaryContainer => _cs.onPrimaryContainer;
  Color get secondary => _cs.secondary;
  Color get onSecondary => _cs.onSecondary;
  Color get secondaryContainer => _cs.secondaryContainer;
  Color get onSecondaryContainer => _cs.onSecondaryContainer;
  Color get tertiary => _cs.tertiary;

  Color get success => _st.success;
  Color get warning => _st.warning;
  Color get neutralGray => _ap.neutralGray;
  Color get primaryBlue => _ap.primaryBlue;
  Color get qrOut => _ap.qrOut;
  Color get qrIn => _ap.qrIn;
  Color get surfaceNavy => _ap.surfaceNavy;
}

class QuickpassTheme {
  static final TextTheme _lightTextTheme = GoogleFonts.interTextTheme();
  static final TextTheme _darkTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

  static final ThemeData light = _buildLight();
  static final ThemeData dark = _buildDark();

  static ThemeData _buildLight() {
    return ThemeData(
      textTheme: _lightTextTheme,
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: QuickpassColors.darkPrimary,
        onPrimary: QuickpassColors.darkOnPrimary,
        primaryContainer: QuickpassColors.darkPrimaryContainer,
        onPrimaryContainer: QuickpassColors.darkOnPrimaryContainer,
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
        surfaceContainerLowest: QuickpassColors.surfaceContainerLowest,
        surfaceContainerLow: QuickpassColors.surfaceContainerLow,
        surfaceContainer: QuickpassColors.surfaceContainer,
        surfaceContainerHigh: QuickpassColors.surfaceContainerHigh,
        surfaceContainerHighest: QuickpassColors.surfaceVariant,
        onSurfaceVariant: QuickpassColors.onSurfaceVariant,
        outline: QuickpassColors.outline,
        outlineVariant: QuickpassColors.outlineVariant,
      ),
      extensions: const [
        StatusColors.light,
        AppColors.light,
      ],
      scaffoldBackgroundColor: QuickpassColors.background,

      appBarTheme: AppBarTheme(
        backgroundColor: QuickpassColors.darkPrimary,
        foregroundColor: QuickpassColors.darkOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: QuickpassColors.darkOnPrimary,
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
          backgroundColor: QuickpassColors.darkPrimary,
          foregroundColor: QuickpassColors.darkOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
          foregroundColor: QuickpassColors.darkPrimary,
          side: const BorderSide(color: QuickpassColors.darkPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QuickpassColors.darkPrimary,
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
          borderSide: const BorderSide(color: QuickpassColors.darkPrimary, width: 2),
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
        indicatorColor: QuickpassColors.darkPrimary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: QuickpassColors.darkPrimary);
          }
          return const IconThemeData(color: QuickpassColors.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: QuickpassColors.darkPrimary);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: QuickpassColors.onSurfaceVariant);
        }),
        elevation: 0,
        height: 80,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: QuickpassColors.surface,
        selectedItemColor: QuickpassColors.darkPrimary,
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
        actionTextColor: QuickpassColors.darkOnPrimary,
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
        backgroundColor: QuickpassColors.darkPrimary,
        foregroundColor: QuickpassColors.darkOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData _buildDark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: _darkTextTheme,
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
        surfaceContainerLowest: QuickpassColors.darkSurfaceContainerLowest,
        surfaceContainer: QuickpassColors.darkSurfaceContainer,
        surfaceContainerHigh: QuickpassColors.darkSurfaceContainerHigh,
        surfaceContainerHighest: QuickpassColors.darkSurfaceVariant,
        onSurfaceVariant: QuickpassColors.darkOnSurfaceVariant,
        outline: QuickpassColors.darkOutline,
        outlineVariant: QuickpassColors.darkOutlineVariant,
      ),
      extensions: const [
        StatusColors.dark,
        AppColors.dark,
      ],
      scaffoldBackgroundColor: QuickpassColors.darkBackground,

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
