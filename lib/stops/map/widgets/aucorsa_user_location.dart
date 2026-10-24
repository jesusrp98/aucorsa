import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_device_compass/flutter_device_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre/maplibre.dart' as ml;
import 'package:material_ui/material_ui.dart';

/// A map-anchored location dot with a compass beam that rotates with the map.
class AucorsaUserLocation extends StatelessWidget {
  final ValueListenable<Position?> position;

  const new({required this.position, super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: position,
    builder: (_, position, _) {
      if (position == null) return const SizedBox.shrink();

      return StreamBuilder<CompassEvent>(
        stream: FlutterCompass.eventsFor(CompassUpdateOptions.balanced),
        builder: (_, snapshot) {
          final event = snapshot.data;
          final heading = snapshot.hasError || (event?.accuracy ?? -1) < 0
              ? null
              : event?.heading;

          return IgnorePointer(
            child: ml.WidgetLayer(
              markers: [
                ml.Marker(
                  point: ml.Geographic(
                    lon: position.longitude,
                    lat: position.latitude,
                  ),
                  size: const Size.square(AucorsaLocationIndicator.size),
                  rotate: true,
                  child: AucorsaLocationIndicator(heading: heading),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class AucorsaLocationIndicator extends StatefulWidget {
  static const size = 128.0;

  /// Compass heading in degrees, or null when a reliable heading is unavailable.
  final double? heading;

  const new({required this.heading, super.key});

  @override
  State<AucorsaLocationIndicator> createState() =>
      _AucorsaLocationIndicatorState();
}

class _AucorsaLocationIndicatorState extends State<AucorsaLocationIndicator>
    with SingleTickerProviderStateMixin {
  late final pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  // Breathe inward and back out, then rest at full size for one second.
  // Keep the white ring and heading beam stationary throughout the pulse.
  late final dotRadius = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 8.0,
        end: 6.75,
      ).chain(CurveTween(curve: Curves.easeInOutSine)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 6.75,
        end: 8.0,
      ).chain(CurveTween(curve: Curves.easeInOutSine)),
      weight: 1,
    ),
    TweenSequenceItem(tween: ConstantTween(8.0), weight: 1),
  ]).animate(pulseController);

  double turns = 0;
  bool get hasHeading => widget.heading?.isFinite ?? false;

  @override
  void initState() {
    super.initState();
    if (hasHeading) turns = widget.heading! / 360;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      pulseController
        ..stop()
        ..value = 0;
    } else if (!pulseController.isAnimating) {
      pulseController.repeat();
    }
  }

  @override
  void dispose() {
    pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AucorsaLocationIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!hasHeading) return;

    final nextTurns = widget.heading! / 360;
    // Cross north using the shortest arc, rather than spinning a full circle.
    turns += (nextTurns - turns + 0.5) % 1 - 0.5;
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedRotation(
      turns: turns,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: CustomPaint(
        size: const Size.square(AucorsaLocationIndicator.size),
        painter: _LocationIndicatorPainter(
          showHeading: hasHeading,
          dotRadius: dotRadius,
        ),
      ),
    ),
  );
}

class _LocationIndicatorPainter extends CustomPainter {
  static const blue = Color(0xFF008FFF);
  final bool showHeading;
  final Animation<double> dotRadius;

  _LocationIndicatorPainter({
    required this.showHeading,
    required this.dotRadius,
  }) : super(repaint: dotRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (showHeading) {
      const radius = 60.0;
      const spread = 75 * pi / 180;
      final bounds = Rect.fromCircle(center: center, radius: radius);
      final beam = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(bounds, -pi / 2 - spread / 2, spread, false)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x80008FFF), Color(0x38008FFF), Color(0x00008FFF)],
            stops: [0, 0.45, 1],
          ).createShader(bounds),
      );
    }

    canvas
      ..drawCircle(
        center + const Offset(0, 1),
        11,
        Paint()
          ..color = const Color(0x33002750)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawCircle(center, 11, Paint()..color = Colors.white)
      ..drawCircle(center, dotRadius.value, Paint()..color = blue);
  }

  @override
  bool shouldRepaint(_LocationIndicatorPainter oldDelegate) =>
      showHeading != oldDelegate.showHeading ||
      dotRadius != oldDelegate.dotRadius;
}
