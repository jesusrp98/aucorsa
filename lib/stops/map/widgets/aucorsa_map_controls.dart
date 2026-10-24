import 'dart:math';

import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/widgets/bus_line_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_ui/material_ui.dart';

final class AucorsaMapCompassButton extends StatelessWidget {
  final ValueListenable<double> rotation;
  final VoidCallback onPressed;

  const new({required this.rotation, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: rotation,
    builder: (_, rotation, _) => AnimatedOpacity(
      opacity: rotation.abs() > 0.001 ? 1 : 0,
      duration: Durations.medium2,
      curve: Curves.easeInOutCubic,
      child: SizedBox.square(
        dimension: kMinInteractiveDimension,
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
    ),
  );
}

final class AucorsaMapActionPill extends StatelessWidget {
  final String? selectedLine;
  final ValueListenable<bool> followLocation;
  final VoidCallback onLinePressed;
  final VoidCallback onLocationPressed;

  const new({
    required this.selectedLine,
    required this.followLocation,
    required this.onLinePressed,
    required this.onLocationPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final line = selectedLine == null
        ? null
        : BusLineUtils.getLine(selectedLine!);
    final lineLabel = line == null
        ? context.l10n.allStops
        : context.l10n.busLine(line.id);

    return Material(
      color: colorScheme.surfaceContainer,
      elevation: theme.floatingActionButtonTheme.elevation ?? 1,
      shape: StadiumBorder(
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: .4),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: kMinInteractiveDimension,
        child: Column(
          mainAxisSize: .min,
          children: [
            SizedBox.square(
              dimension: kMinInteractiveDimension,
              child: IconButton(
                onPressed: onLinePressed,
                color: colorScheme.onSurface,
                icon: Semantics(
                  label: '${context.l10n.busLines}: $lineLabel',
                  excludeSemantics: true,
                  child: line == null
                      ? const Icon(Symbols.signpost_rounded, size: 24, fill: .5)
                      : CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              BusLineTile.resolveLineBackgroundColor(
                                context,
                                line.color,
                              ),
                          foregroundColor: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                line.id,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            SizedBox.square(
              dimension: kMinInteractiveDimension,
              child: ValueListenableBuilder<bool>(
                valueListenable: followLocation,
                builder: (_, followLocation, _) =>
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: followLocation ? 1 : 0),
                      duration: kThemeAnimationDuration,
                      curve: Curves.easeInOutCubic,
                      builder: (_, value, _) => IconButton(
                        onPressed: onLocationPressed,
                        color: colorScheme.onSurface,
                        icon: Icon(
                          Symbols.near_me_rounded,
                          fill: value,
                          size: 24,
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
