import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';

class ThemeCubit extends HydratedCubit<ThemeMode> {
  new() : super(ThemeMode.system);

  void setThemeMode(ThemeMode themeMode) => emit(themeMode);

  @override
  ThemeMode fromJson(Map<String, dynamic> json) =>
      ThemeMode.values[json['themeMode'] as int];

  @override
  Map<String, dynamic> toJson(ThemeMode state) => {'themeMode': state.index};
}
