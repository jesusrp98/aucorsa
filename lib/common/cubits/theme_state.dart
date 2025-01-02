import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final bool useDeviceTint;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.useDeviceTint = true,
  });

  factory ThemeState.fromJson(Map<String, dynamic> json) => ThemeState(
        themeMode: ThemeMode.values[json['themeMode'] as int],
        useDeviceTint: json['useDeviceTint'] as bool,
      );

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? useDeviceTint,
  }) =>
      ThemeState(
        themeMode: themeMode ?? this.themeMode,
        useDeviceTint: useDeviceTint ?? this.useDeviceTint,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'useDeviceTint': useDeviceTint,
      };

  @override
  List<Object> get props => [
        themeMode,
        useDeviceTint,
      ];
}
