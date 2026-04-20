import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================================
// LIGHT MODE COLORS
// ============================================================================
const Color lightPrimaryBlue = Color(0xFF2F6FED);
const Color lightSecondaryOrange = Color(0xFFFF8A3D);
const Color lightErrorRed = Color(0xFFDC2626);
const Color lightSuccessGreen = Color(0xFF10B981);
const Color lightWarningOrange = Color(0xFFF59E0B);

const Color lightBackgroundMain = Color(0xFFFAFAFA);
const Color lightBackgroundAlt = Color(0xFFF3F4F6);
const Color lightSurfaceCard = Color(0xFFFFFFFF);
const Color lightTextPrimary = Color(0xFF1F2937);
const Color lightTextSecondary = Color(0xFF6B7280);
const Color lightBorderSubtle = Color(0xFFE5E7EB);
const Color lightBorderMedium = Color(0xFFD1D5DB);

const Color lightOrange = Color(0xFFFFF3E6);

// ============================================================================
// DARK MODE COLORS
// ============================================================================
const Color darkPrimaryBlue = Color(0xFF3B82F6);
const Color darkSecondaryOrange = Color(0xFFFF9D56);
const Color darkErrorRed = Color(0xFFF87171);
const Color darkSuccessGreen = Color(0xFF34D399);
const Color darkWarningOrange = Color(0xFFFBBF24);

const Color darkBackgroundMain = Color(0xFF0F172A);
const Color darkBackgroundAlt = Color(0xFF1A202C);
const Color darkSurfaceCard = Color(0xFF1E293B);
const Color darkSurfaceCardGlass = Color(0xCC1E293B);
const Color darkTextPrimary = Color(0xFFF1F5F9);
const Color darkTextSecondary = Color(0xFFC7D2E0);
const Color darkBorderSubtle = Color(0xFF334155);

// ============================================================================
// GRADIENT DEFINITIONS
// ============================================================================
const List<Color> orangeGradient = <Color>[
  Color(0xFFFF8A3D),
  Color(0xFFFF6A00),
];
const List<Color> greenGradient = <Color>[Color(0xFF2ECC71), Color(0xFF27AE60)];
const List<Color> purpleGradient = <Color>[
  Color(0xFF8E5CF6),
  Color(0xFF6C3DF0),
];
const List<Color> blueGradient = <Color>[Color(0xFF4A90E2), Color(0xFF357ABD)];

// ============================================================================
// SEMANTIC COLOR ALIASES FOR BACKWARD COMPATIBILITY
// ============================================================================
const Color primaryBlue = lightPrimaryBlue;
const Color darkText = lightTextPrimary;
const Color lightBackground = lightBackgroundAlt;
const Color whiteCard = lightSurfaceCard;
const Color greyDivider = lightBorderSubtle;
const Color darkBackground = darkBackgroundMain;
const Color darkCard = darkSurfaceCard;
const Color darkCardGlass = darkSurfaceCardGlass;
const Color darkTextLight = darkTextPrimary;

class AppTheme {
  AppTheme._();

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static void setDarkMode(bool value) {
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  static void toggleTheme() {
    themeModeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
  }

  // ========================================================================
  // LIGHT THEME
  // ========================================================================
  static ThemeData get lightTheme {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: lightPrimaryBlue,
        secondary: lightSecondaryOrange,
        tertiary: lightWarningOrange,
        error: lightErrorRed,
        surface: lightSurfaceCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onError: Colors.white,
        outline: lightBorderMedium,
      ),
      scaffoldBackgroundColor: lightBackgroundAlt,
      cardColor: lightSurfaceCard,
    );

    return base.copyWith(
      // TEXT THEME: Using Poppins with proper colors for light mode
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: lightTextSecondary,
        ),
      ),

      // APP BAR THEME
      appBarTheme: AppBarTheme(
        backgroundColor: lightPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // CHIP THEME
      chipTheme: ChipThemeData(
        selectedColor: lightPrimaryBlue.withValues(alpha: 0.16),
        checkmarkColor: lightPrimaryBlue,
        side: const BorderSide(color: lightBorderSubtle),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // INPUT DECORATION THEME
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBackgroundMain,
        labelStyle: const TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: lightTextSecondary.withValues(alpha: 0.6),
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightPrimaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightErrorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightErrorRed, width: 2),
        ),
      ),

      // CARD THEME
      cardTheme: CardThemeData(
        color: lightSurfaceCard,
        elevation: 2,
        shadowColor: const Color(0x22000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // ELEVATED BUTTON THEME
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          elevation: 2,
        ),
      ),

      // OUTLINED BUTTON THEME
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: const BorderSide(color: lightBorderMedium, width: 1.5),
        ),
      ),

      // FILLED BUTTON THEME
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // SWITCH THEME
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return lightPrimaryBlue;
          }
          return lightBorderMedium;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return lightPrimaryBlue.withValues(alpha: 0.3);
          }
          return lightBorderSubtle;
        }),
      ),

      // BOTTOM NAVIGATION BAR THEME
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: lightPrimaryBlue,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        backgroundColor: lightSurfaceCard,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: lightPrimaryBlue,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: lightTextSecondary,
        ),
      ),

      // DIVIDER COLOR
      dividerColor: lightBorderSubtle,

      // SNACK BAR THEME
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: lightTextPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ========================================================================
  // DARK THEME
  // ========================================================================
  static ThemeData get darkTheme {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: darkPrimaryBlue,
        secondary: darkSecondaryOrange,
        tertiary: darkWarningOrange,
        error: darkErrorRed,
        surface: darkSurfaceCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onError: darkSurfaceCard,
        outline: darkBorderSubtle,
      ),
      scaffoldBackgroundColor: darkBackgroundMain,
      cardColor: darkSurfaceCard,
    );

    return base.copyWith(
      // TEXT THEME: Using Poppins with proper colors for dark mode
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkTextSecondary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary.withValues(alpha: 0.8),
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: darkTextSecondary,
        ),
      ),

      // APP BAR THEME
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceCard,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // CHIP THEME
      chipTheme: ChipThemeData(
        selectedColor: darkPrimaryBlue.withValues(alpha: 0.28),
        checkmarkColor: darkPrimaryBlue,
        side: BorderSide(color: darkBorderSubtle),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // INPUT DECORATION THEME
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackgroundAlt,
        labelStyle: const TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: darkTextSecondary.withValues(alpha: 0.6),
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkPrimaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkErrorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkErrorRed, width: 2),
        ),
      ),

      // CARD THEME
      cardTheme: CardThemeData(
        color: darkSurfaceCardGlass,
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // ELEVATED BUTTON THEME
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          elevation: 4,
        ),
      ),

      // OUTLINED BUTTON THEME
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(color: darkBorderSubtle, width: 1.5),
        ),
      ),

      // FILLED BUTTON THEME
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // SWITCH THEME
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return darkPrimaryBlue;
          }
          return darkBorderSubtle;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return darkPrimaryBlue.withValues(alpha: 0.3);
          }
          return darkBorderSubtle.withValues(alpha: 0.5);
        }),
      ),

      // BOTTOM NAVIGATION BAR THEME
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: darkPrimaryBlue,
        unselectedItemColor: darkTextSecondary.withValues(alpha: 0.7),
        type: BottomNavigationBarType.fixed,
        backgroundColor: darkSurfaceCardGlass,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: darkPrimaryBlue,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: darkTextSecondary.withValues(alpha: 0.7),
        ),
      ),

      // DIVIDER COLOR
      dividerColor: darkBorderSubtle,

      // SNACK BAR THEME
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkSurfaceCard,
        contentTextStyle: const TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
