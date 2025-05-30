import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

Future<void> showMapAttributionDialog(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,

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
      minimum: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final attribution in attributions.entries)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              onTap: () => launchUrlString(attribution.value),
              leading: const Icon(Symbols.copyright_rounded),
              title: Text(attribution.key),
              trailing: const Icon(Symbols.chevron_right_rounded),
            ),
        ],
      ),
    );
  }
}
