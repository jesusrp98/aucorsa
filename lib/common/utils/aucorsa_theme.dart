import 'package:flutter/material.dart';
import 'package:lucky_navigation_bar/lucky_navigation_bar.dart';

class AucorsaTheme {
  const AucorsaTheme._();

  static const defaultColor = Colors.green;

  static final defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: defaultColor,
  );

  static final defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: defaultColor,
    brightness: Brightness.dark,
  );

  static ThemeData from({required ColorScheme colorScheme}) => ThemeData(
    colorScheme: colorScheme,
    fontFamily: 'Rubik',
    iconTheme: const IconThemeData(opticalSize: 24),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      sizeConstraints: BoxConstraints.tightFor(
        width: LuckyNavigationBar.height,
        height: LuckyNavigationBar.height,
      ),
      shape: CircleBorder(),
      iconSize: 28,
      elevation: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: colorScheme.surfaceContainerHighest,
      focusedBorder: _generateInputBorder(colorScheme.primary),
      enabledBorder: _generateInputBorder(),
      filled: true,
    ),
    appBarTheme: AppBarTheme(
      surfaceTintColor: Colors.transparent,
      backgroundColor: colorScheme.surface,
      shadowColor: colorScheme.shadow,
    ),
  );

  static InputBorder _generateInputBorder([Color color = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: color,
          width: 2,
        ),
      );
}
