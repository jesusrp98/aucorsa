import 'dart:async';

import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/live_activity/live_activity_cubit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Makes the complete arrival row, including its estimates, a tracking target.
class TargetBusLine extends StatelessWidget {
  const new({
    required this.stopID,
    required this.stopName,
    required this.lineID,
    required this.child,
    super.key,
  });

  final int stopID;
  final String stopName;
  final String lineID;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LiveActivityCubit>().state;
    if (!state.supported) return child;
    final selected = state.stopID == stopID && state.lineID == lineID;
    final borderRadius = BorderRadius.circular(12);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          // Keep taps inside this row while a request is pending, so they
          // cannot trigger the stop card's expand/collapse gesture.
          onTap: () => _target(context),
          child: child,
        ),
      ),
    );
  }

  Future<void> _target(BuildContext context) async {
    final cubit = context.read<LiveActivityCubit>();
    if (cubit.state.busy) return;
    if (!cubit.state.enabled) {
      _showFailure(context, LiveActivityFailure.disabled);
      return;
    }
    if (cubit.state.stopID != stopID || cubit.state.lineID != lineID) {
      final failure = await cubit.start(
        stopID: stopID,
        lineID: lineID,
        stopName: stopName,
        language: Localizations.localeOf(context).languageCode,
      );
      if (!context.mounted) return;
      if (failure != null) {
        _showFailure(context, failure);
        return;
      }
    }
    unawaited(HapticFeedback.lightImpact());
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.l10n.liveActivityTargeting(lineID, stopName)),
        ),
      );
  }
}

void _showFailure(BuildContext context, LiveActivityFailure failure) {
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          failure == LiveActivityFailure.disabled
              ? context.l10n.liveActivityDisabled
              : context.l10n.liveActivityFailed,
        ),
      ),
    );
}
