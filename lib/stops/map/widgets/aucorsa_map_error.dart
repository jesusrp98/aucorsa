import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

final class AucorsaMapError extends StatelessWidget {
  final VoidCallback onRetry;

  const AucorsaMapError({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.map_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.mapLoadError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Symbols.refresh_rounded),
            label: Text(context.l10n.retry),
          ),
        ],
      ),
    ),
  );
}
