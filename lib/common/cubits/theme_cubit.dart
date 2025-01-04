import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void setThemeMode(ThemeMode themeMode) => emit(themeMode);

  @override
  ThemeMode fromJson(Map<String, dynamic> json) =>
      ThemeMode.values[json['themeMode'] as int];

  @override
  Map<String, dynamic> toJson(ThemeMode state) => {'themeMode': state.index};
}
