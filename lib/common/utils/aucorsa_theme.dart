import 'package:flutter/material.dart';
import 'package:lucky_navigation_bar/lucky_navigation_bar.dart';

class AucorsaTheme {
  const new _();

  /// Aucorsa main green color
  static const defaultColor = Color(0xFF00AA16);

  static final defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: defaultColor,
    dynamicSchemeVariant: DynamicSchemeVariant.rainbow,
  );

  static final defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: defaultColor,
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.rainbow,
  );

  static ThemeData from({required ColorScheme colorScheme}) {
    final resolvedColorScheme = colorScheme.copyWith(
      surface: colorScheme.brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
    );

    return ThemeData(
      colorScheme: resolvedColorScheme,
      fontFamily: 'Rubik',
      iconTheme: const IconThemeData(opticalSize: 24),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        sizeConstraints: const BoxConstraints.tightFor(
          width: LuckyNavigationBar.height,
          height: LuckyNavigationBar.height,
        ),
        shape: CircleBorder(
          side: BorderSide(
            color: resolvedColorScheme.outlineVariant.withValues(alpha: .4),
            width: 0.5,
          ),
        ),
        iconSize: 28,
        elevation: 1,
        backgroundColor: resolvedColorScheme.surfaceContainer,
        foregroundColor: resolvedColorScheme.onSurfaceVariant,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: resolvedColorScheme.surfaceContainerHighest,
        focusedBorder: _generateInputBorder(resolvedColorScheme.primary),
        enabledBorder: _generateInputBorder(),
        filled: true,
      ),
      appBarTheme: AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: resolvedColorScheme.surface,
        shadowColor: resolvedColorScheme.shadow,
      ),
    );
  }

  static InputBorder _generateInputBorder([Color color = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: color, width: 2),
      );
}
