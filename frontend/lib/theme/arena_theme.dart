import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'arena_colors.dart';

/// Typography helpers: Bebas Neue for poster headings, Teko for scoreboard digits.
class ArenaText {
  static TextStyle display(double size,
          {Color color = Arena.chalk, double spacing = 1.2}) =>
      GoogleFonts.bebasNeue(
          fontSize: size, color: color, letterSpacing: spacing, height: 1.0);

  static TextStyle digits(double size, {Color color = Arena.gold}) =>
      GoogleFonts.teko(
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w600,
          height: 1.0,
          letterSpacing: 2);
}

class ArenaTheme {
  /// Builds the theme around one accent colour (each role gets its own).
  static ThemeData build(Color accent) {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final scheme =
        ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark)
            .copyWith(
      primary: accent,
      onPrimary: Arena.night,
      surface: Arena.stand,
      onSurface: Arena.chalk,
      error: Arena.redCard,
    );
    final text = GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: Arena.chalk, displayColor: Arena.chalk);

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: Arena.night,
      textTheme: text,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Arena.night.withValues(alpha: .6),
        labelStyle: const TextStyle(color: Arena.mist),
        hintStyle: const TextStyle(color: Arena.mist),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(Colors.white12),
        enabledBorder: border(Colors.white12),
        focusedBorder: border(accent, 2),
        errorBorder: border(Arena.redCard),
        focusedErrorBorder: border(Arena.redCard, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Arena.night,
          minimumSize: const Size(0, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: ArenaText.display(22, spacing: 2.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Arena.standHi,
        contentTextStyle: const TextStyle(color: Arena.chalk),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}