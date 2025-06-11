import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_symbols_icons/symbols.dart';

Future<void> showLocationPermissionDialog(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => const _LocationPermissionDialogView(),
    );

class _LocationPermissionDialogView extends StatelessWidget {
  const _LocationPermissionDialogView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.near_me_rounded,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.locationPermissionTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.l10n.locationPermissionDescription,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(56),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onTertiaryContainer,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer,
                ),
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.of(context).pop();
                },
                child: Text(context.l10n.openSettings),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(56),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                onPressed: Navigator.of(context).pop,
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
