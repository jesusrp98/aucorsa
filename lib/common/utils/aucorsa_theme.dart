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

  static final _lightPendingColor = ColorScheme.fromSeed(
    seedColor: Colors.amber,
  ).primary;

  static final _darkPendingColor = ColorScheme.fromSeed(
    seedColor: Colors.amber,
    brightness: Brightness.dark,
  ).primary;

  /// Amber that flags pending states, built from the same tonal machinery as
  /// the rest of the palette so it sits well on the app surfaces.
  static Color pendingColor(Brightness brightness) =>
      brightness == Brightness.dark ? _darkPendingColor : _lightPendingColor;

  static ThemeData from({required ColorScheme colorScheme}) => ThemeData(
    colorScheme: colorScheme,
    fontFamily: 'Rubik',
    iconTheme: const IconThemeData(opticalSize: 24),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      sizeConstraints: const BoxConstraints.tightFor(
        width: LuckyNavigationBar.height,
        height: LuckyNavigationBar.height,
      ),
      shape: CircleBorder(
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: .4),
          width: 0.5,
        ),
      ),
      iconSize: 28,
      elevation: 1,
      backgroundColor: colorScheme.surfaceContainer,
      foregroundColor: colorScheme.onSurfaceVariant,
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
