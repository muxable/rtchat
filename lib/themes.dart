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

const accentColor = Color(0xFF009FDF);
const detailColor = Color(0xFF121312);
const textFieldColor = Color(0xFF1D1D1F);

const lightAccentColor = Color(0xFF006591);
const lightTextFieldColor = Color(0xFFEDEDEF);

final primarySwatch = generateMaterialColor(accentColor);

class Themes {
  static final lightTheme = ThemeData(
      fontFamily: GoogleFonts.poppins().fontFamily,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: primarySwatch,
        accentColor: lightAccentColor,
      ).copyWith(
        primary: lightAccentColor,
        secondary: lightAccentColor,
        tertiary: detailColor,
        background: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        fillColor: lightTextFieldColor,
      ),
      appBarTheme: const AppBarTheme(color: detailColor),
      tabBarTheme: const TabBarTheme(labelColor: lightAccentColor),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return lightAccentColor;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return lightAccentColor;
          }
          return null;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return lightAccentColor;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return lightAccentColor;
          }
          return null;
        }),
      ));

  static final darkTheme = ThemeData(
    fontFamily: GoogleFonts.poppins().fontFamily,
    canvasColor: Colors.black,
    cardColor: Colors.black,
    appBarTheme: const AppBarTheme(
      color: detailColor,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: primarySwatch,
      brightness: Brightness.dark,
      backgroundColor: detailColor,
      accentColor: accentColor,
    ).copyWith(primary: accentColor, tertiary: detailColor),
    dialogBackgroundColor: Colors.black,
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: detailColor),
    drawerTheme: const DrawerThemeData(backgroundColor: detailColor),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: textFieldColor,
    ),
    textTheme: const TextTheme(headlineMedium: TextStyle(color: Colors.white)),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return null;
        }
        if (states.contains(MaterialState.selected)) {
          return accentColor;
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return null;
        }
        if (states.contains(MaterialState.selected)) {
          return accentColor;
        }
        return null;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return null;
        }
        if (states.contains(MaterialState.selected)) {
          return accentColor;
        }
        return null;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return null;
        }
        if (states.contains(MaterialState.selected)) {
          return accentColor;
        }
        return null;
      }),
    ),
  );
}
