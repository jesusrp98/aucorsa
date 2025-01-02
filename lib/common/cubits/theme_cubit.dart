import 'package:aucorsa/common/cubits/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());

  static bool supportsDeviceTint(BuildContext context) =>
      Theme.of(context).platform != TargetPlatform.iOS;

  void setThemeMode(ThemeMode themeMode) =>
      emit(state.copyWith(themeMode: themeMode));

  void setUseDeviceTint(bool useDeviceTint) =>
      emit(state.copyWith(useDeviceTint: useDeviceTint));

  @override
  ThemeState fromJson(Map<String, dynamic> json) => ThemeState.fromJson(json);

  @override
  Map<String, dynamic> toJson(ThemeState state) => state.toJson();
}
