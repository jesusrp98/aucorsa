import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

final class AucorsaMapCompassButton extends StatelessWidget {
  final ValueListenable<double> rotation;
  final VoidCallback onPressed;

  const AucorsaMapCompassButton({
    required this.rotation,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: rotation,
    builder: (_, rotation, _) => AnimatedOpacity(
      opacity: rotation.abs() > 0.001 ? 1 : 0,
      duration: Durations.medium2,
      curve: Curves.easeInOutCubic,
      child: FloatingActionButton.small(
        heroTag: null,
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        onPressed: onPressed,
        child: Transform.rotate(
          angle: rotation - pi / 4,
          child: const Icon(Symbols.explore_rounded, size: 24),
        ),
      ),
    ),
  );
}

final class AucorsaMapLocationButton extends StatelessWidget {
  final ValueListenable<bool> followLocation;
  final VoidCallback onPressed;

  const AucorsaMapLocationButton({
    required this.followLocation,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: followLocation,
    builder: (_, followLocation, _) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: followLocation ? 1 : 0),
      duration: kThemeAnimationDuration,
      curve: Curves.easeInOutCubic,
      builder: (_, value, _) => FloatingActionButton.small(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        heroTag: null,
        onPressed: onPressed,
        child: Icon(Symbols.near_me_rounded, fill: value, size: 24),
      ),
    ),
  );
}
