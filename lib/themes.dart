import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

MaterialColor generateMaterialColor(Color color) {
  return MaterialColor(color.value, {
    50: tintColor(color, 0.5),
    100: tintColor(color, 0.4),
    200: tintColor(color, 0.3),
    300: tintColor(color, 0.2),
    400: tintColor(color, 0.1),
    500: tintColor(color, 0),
    600: tintColor(color, -0.1),
    700: tintColor(color, -0.2),
    800: tintColor(color, -0.3),
    900: tintColor(color, -0.4),
  });
}

int tintValue(int value, double factor) =>
    max(0, min((value + ((255 - value) * factor)).round(), 255));

Color tintColor(Color color, double factor) => Color.fromRGBO(
    tintValue(color.red, factor),
    tintValue(color.green, factor),
    tintValue(color.blue, factor),
    1);

final primarySwatch = generateMaterialColor(Themes.accentColor);

class Themes {
  static const accentColor = Color(0xFF009FDF);
  static const detailColor = Color(0xFF121312);
  static const textFieldColor = Color(0xFF1D1D1F);

  static const lightAccentColor = Color(0xFF006591);
  static const lightTextFieldColor = Color(0xFFEDEDEF);

  static final lightTheme = ThemeData(
    fontFamily: GoogleFonts.poppins().fontFamily,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: primarySwatch,
      accentColor: Themes.lightAccentColor,
    ).copyWith(
      primary: Themes.lightAccentColor,
      secondary: Themes.lightAccentColor,
      tertiary: Themes.detailColor,
      background: Colors.white,
    ),
    toggleableActiveColor: Themes.lightAccentColor,
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Themes.lightTextFieldColor,
    ),
    appBarTheme: const AppBarTheme(color: Themes.detailColor),
  );

  static final darkTheme = ThemeData(
    fontFamily: GoogleFonts.poppins().fontFamily,
    canvasColor: Colors.black,
    cardColor: Colors.black,
    appBarTheme: const AppBarTheme(
      color: Themes.detailColor,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: primarySwatch,
      brightness: Brightness.dark,
      backgroundColor: Themes.detailColor,
      accentColor: Themes.accentColor,
    ).copyWith(primary: Themes.accentColor, tertiary: Themes.detailColor),
    dialogBackgroundColor: Colors.black,
    toggleableActiveColor: Themes.accentColor,
    bottomSheetTheme:
        const BottomSheetThemeData(backgroundColor: Themes.detailColor),
    drawerTheme: const DrawerThemeData(backgroundColor: Themes.detailColor),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Themes.textFieldColor,
    ),
    textTheme: const TextTheme(headlineMedium: TextStyle(color: Colors.white)),
  );
}
