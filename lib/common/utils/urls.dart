import 'package:flutter/material.dart';

class Urls {
  const Urls._();

  static const appSource = 'https://github.com/jesusrp98/aucorsa';

  static const authorProfile = 'https://jesusrp98.com';

  static const emailUrl = 'mailto:work@jesusrp98.com?subject=Sobre Aucorsa GO!';

  static String resolveMapStyleUrl({
    required Brightness brightness,
    required String apiKey,
  }) => brightness == Brightness.light
      ? _lightMapStyleUrl + apiKey
      : _darkMapStyleUrl + apiKey;

  static const _lightMapStyleUrl =
      'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}@2x.png?api_key=';
  static const _darkMapStyleUrl =
      'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png?api_key=';
}
