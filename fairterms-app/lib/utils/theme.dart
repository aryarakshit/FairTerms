// ignore_for_file: unused_element
/// FairTerms theme — Fixmyitch-inspired minimal palette.
///
/// Cream paper canvas (#F7F4EE), near-black ink, sage accent, clay alert.
/// Serif (Fraunces) for display + headings, Inter for body/UI, JetBrains Mono
/// for numeric/benchmark values.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // --- Paper surfaces -----------------------------------------------------
  /// Page canvas — warm off-white (#F7F4EE).
  static const Color background = Color(0xFFF7F4EE);

  /// Card / inset fill — deeper cream (#EFEAE0).
  static const Color surface = Color(0xFFEFEAE0);

  /// Secondary inset — slightly warmer (#E8E1D2).
  static const Color surfaceVariant = Color(0xFFE8E1D2);

  // --- Ink ----------------------------------------------------------------
  /// Primary text — near-black (#141311).
  static const Color ink = Color(0xFF141311);

  /// Body text — warm dark (#4A463E).
  static const Color inkMuted = Color(0xFF4A463E);

  /// Muted / caption — warm grey (#8A8578).
  static const Color inkFaint = Color(0xFF8A8578);

  /// Inverted (for dark chips/buttons).
  static const Color onBackground = ink;
  static const Color onSurface = ink;
  static const Color onPrimary = background;
  static const Color onSecondary = background;

  // --- Hairlines ----------------------------------------------------------
  /// Default border — cream line (#E3DDD0).
  static const Color outline = Color(0xFFE3DDD0);

  /// Hover / inset variant (#D4CDBB).
  static const Color outlineVariant = Color(0xFFD4CDBB);

  // --- Accents ------------------------------------------------------------
  /// Sage — primary accent / fair scores (#3E5C3A).
  static const Color primary = Color(0xFF3E5C3A);

  /// Ink near-black — default CTA.
  static const Color secondary = Color(0xFF141311);

  /// Clay — error / severe bias (#B94A2B).
  static const Color error = Color(0xFFB94A2B);

  /// Amber — warning / moderate (#C58E2A).
  static const Color warning = Color(0xFFC58E2A);

  // --- Semantic score colors ---------------------------------------------
  static const Color scoreLow = error;
  static const Color scoreMid = warning;
  static const Color scoreHigh = primary;

  // --- Legacy aliases kept for widget compatibility -----------------------
  static const Color mint = primary;
  static const Color lavender = Color(0xFF7A6A8C);
  static const Color sky = Color(0xFF3F5E7A);

  // --- Verdict gradients (subtle, tonal) ---------------------------------
  static const LinearGradient biasSevereGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB94A2B), Color(0xFF8F3720)],
  );

  static const LinearGradient biasModerateGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC58E2A), Color(0xFF9A6C1F)],
  );

  static const LinearGradient fairGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3E5C3A), Color(0xFF2A4026)],
  );
}

/// Soft paper shadow — barely-there elevation.
List<BoxShadow> brutalShadow({double dx = 0, double dy = 1}) => [
      BoxShadow(
        color: AppColors.ink.withValues(alpha: 0.04),
        offset: Offset(dx, dy),
        blurRadius: 2,
        spreadRadius: 0,
      ),
    ];

List<BoxShadow> brutalShadowSmall() => brutalShadow(dx: 0, dy: 1);

List<BoxShadow> brutalShadowNeutral({double dx = 0, double dy = 1}) => [
      BoxShadow(
        color: AppColors.ink.withValues(alpha: 0.06),
        offset: Offset(dx, dy),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ];

/// Builds the FairTerms light theme.
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: Color(0xFFE6ECDF),
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: Color(0xFFEFEAE0),
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.warning,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF5E8CF),
    onTertiaryContainer: AppColors.warning,
    error: AppColors.error,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF5DCD1),
    onErrorContainer: AppColors.error,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.inkMuted,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: Color(0xFF000000),
    scrim: Color(0x33000000),
    inverseSurface: AppColors.ink,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.primary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    textTheme: _buildTextTheme(),
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
    ),
    cardTheme: CardThemeData(
      color: AppColors.background,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.background,
        elevation: 0,
        minimumSize: const Size(double.infinity, 48),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: AppColors.outline, width: 1),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.outline, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.outline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.ink, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.inkMuted,
        letterSpacing: 0,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.inkFaint,
        fontWeight: FontWeight.w400,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.background,
      selectedColor: AppColors.ink,
      labelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.inkMuted,
        letterSpacing: 0.1,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.background,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
      side: const BorderSide(color: AppColors.outline, width: 1),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        letterSpacing: -0.3,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.inkMuted,
        height: 1.6,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: GoogleFonts.inter(
        color: AppColors.background,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        side: BorderSide(color: AppColors.outline, width: 1),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.ink,
      linearTrackColor: AppColors.surface,
    ),
    iconTheme: const IconThemeData(color: AppColors.ink),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.background
              : AppColors.inkFaint),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surface),
      trackOutlineColor: WidgetStateProperty.all(AppColors.outline),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.ink
              : Colors.transparent),
      checkColor: WidgetStateProperty.all(AppColors.background),
      side: const BorderSide(color: AppColors.outline, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}

TextTheme _buildTextTheme() {
  TextStyle display(double size, {double letter = -1.2}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w300,
        letterSpacing: letter,
        color: AppColors.ink,
        height: 1.05,
      );

  TextStyle headline(double size) => GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
        color: AppColors.ink,
        height: 1.15,
      );

  TextStyle title(double size, {FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -0.1,
        color: AppColors.ink,
      );

  TextStyle body(double size) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.inkMuted,
        height: 1.6,
      );

  TextStyle label(double size, {double letter = 0.1}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: letter,
        color: AppColors.inkFaint,
      );

  return TextTheme(
    displayLarge: display(56, letter: -1.6),
    displayMedium: display(44, letter: -1.2),
    displaySmall: display(32, letter: -0.8),
    headlineLarge: headline(26),
    headlineMedium: headline(22),
    headlineSmall: headline(18),
    titleLarge: title(16),
    titleMedium: title(14),
    titleSmall: title(13),
    bodyLarge: body(15),
    bodyMedium: body(13),
    bodySmall: body(12),
    labelLarge: label(12),
    labelMedium: label(11),
    labelSmall: label(10),
  );
}
