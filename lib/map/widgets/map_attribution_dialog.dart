import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

Future<void> showMapAttributionDialog(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => const _MapAttributionDialogView(),
    );

class _MapAttributionDialogView extends StatelessWidget {
  static const attributions = {
    'OpenStreetMap': 'https://www.openstreetmap.org/copyright',
    'OpenMapTiles': 'https://openmaptiles.org/',
    'Stadia Maps': 'https://stadiamaps.com/',
  };

  const _MapAttributionDialogView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final attribution in attributions.entries)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () => launchUrlString(attribution.value),
                child: Text('© ${attribution.key}'),
              ),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
