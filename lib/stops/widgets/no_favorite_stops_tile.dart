import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:aucorsa/stops/pages/stops_map_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class NoFavoriteStopsTile extends StatelessWidget {
  const NoFavoriteStopsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.transparent,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: GestureDetector(
        child: ListViewSectionTile(
          leading: const Icon(Symbols.favorite_rounded, fill: 1),
          title: Text(
            context.l10n.noFavoritesTitle,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(context.l10n.noFavoritesSubtitle),
          onTap: () => context.go(StopsMapPage.path),
        ),
      ),
    );
  }
}
