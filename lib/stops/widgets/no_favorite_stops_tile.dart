import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/stops/pages/stops_map_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class NoFavoriteStopsTile extends StatelessWidget {
  const NoFavoriteStopsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.transparent,
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () => context.go(StopsMapPage.path),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            child: const Icon(Symbols.favorite_rounded, fill: 1),
          ),
          title: Text(
            context.l10n.noFavoritesTitle,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(context.l10n.noFavoritesSubtitle),
          trailing: const Icon(Symbols.chevron_right_rounded),
        ),
      ),
    );
  }
}
