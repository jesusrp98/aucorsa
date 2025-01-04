import 'package:flutter/material.dart';

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
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          },
        ),
        appBarTheme: AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: colorScheme.surface,
          shadowColor: colorScheme.shadow,
        ),
      );
}
