import 'package:aucorsa/common/cubits/theme_cubit.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

Future<void> showThemeBottomSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _ThemeBottomSheet(),
      useSafeArea: true,
    );

class _ThemeBottomSheet extends StatelessWidget {
  const _ThemeBottomSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final themeMode in ThemeMode.values) _ThemeListTile(themeMode),
        ],
      ),
    );
  }
}

class _ThemeListTile extends StatelessWidget {
  final ThemeMode themeMode;

  const _ThemeListTile(this.themeMode);

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ThemeCubit>().state == themeMode;
    final foregroundColor = selected
        ? Theme.of(context).colorScheme.onPrimaryFixed
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: Icon(_iconData, fill: 1),
      title: Text(_title(context)),
      onTap: () => context.read<ThemeCubit>().setThemeMode(themeMode),
      iconColor: foregroundColor,
      tileColor: selected ? Theme.of(context).colorScheme.primaryFixed : null,
      titleTextStyle: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: foregroundColor),
      trailing: selected
          ? const Icon(Symbols.check_circle_rounded, fill: 1)
          : Icon(
              Symbols.circle_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
    );
  }

  IconData get _iconData => switch (themeMode) {
    ThemeMode.system => Symbols.palette_rounded,
    ThemeMode.light => Symbols.light_mode_rounded,
    ThemeMode.dark => Symbols.dark_mode_rounded,
  };

  String _title(BuildContext context) => switch (themeMode) {
    ThemeMode.system => context.l10n.systemTheme,
    ThemeMode.light => context.l10n.lightTheme,
    ThemeMode.dark => context.l10n.darkTheme,
  };
}
