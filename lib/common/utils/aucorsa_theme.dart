import 'package:flutter/material.dart';

class AucorsaTheme {
  const AucorsaTheme._();

  static ThemeData from({required ColorScheme colorScheme}) => ThemeData(
        colorScheme: colorScheme,
        fontFamily: 'Rubik',
        iconTheme: const IconThemeData(opticalSize: 24),
        appBarTheme: AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: colorScheme.surface,
          shadowColor: colorScheme.shadow,
          centerTitle: true,
        ),
      );
}
