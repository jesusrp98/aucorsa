import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

abstract final class BusStopCustomIcons {
  static const values = [
    Symbols.home_rounded,
    Symbols.school_rounded,
    Symbols.work_rounded,
    Symbols.flag_rounded,
    Symbols.sports_soccer_rounded,
    Symbols.music_note_rounded,
    Symbols.location_on_rounded,
    Symbols.local_hospital_rounded,
    Symbols.balance_rounded,
    Symbols.favorite_rounded,
    Symbols.bolt_rounded,
    Symbols.group_rounded,
    Symbols.construction_rounded,
    Symbols.park_rounded,
    Symbols.train_rounded,
    Symbols.travel_rounded,
    Symbols.directions_car_rounded,
    Symbols.directions_boat_rounded,
  ];

  static IconData? resolve(int? codePoint) {
    if (codePoint == null) return null;

    for (final icon in values) {
      if (icon.codePoint == codePoint) return icon;
    }

    return null;
  }
}
