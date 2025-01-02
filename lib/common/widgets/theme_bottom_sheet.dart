import 'package:aucorsa/common/cubits/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

Future<void> showThemeBottomSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _ThemeBottomSheet(),
    );

class _ThemeBottomSheet extends StatelessWidget {
  const _ThemeBottomSheet();

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;

    return SafeArea(
      minimum: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ThemeCubit.supportsDeviceTint(context)) ...[
            SwitchListTile(
              secondary: const Icon(Symbols.colorize_rounded, fill: 1),
              title: const Text('Usar color del dispositivo'),
              value: themeState.useDeviceTint,
              onChanged: context.read<ThemeCubit>().setUseDeviceTint,
            ),
            const Divider(),
          ],
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
    final themeState = context.watch<ThemeCubit>().state;
    final selected = themeState.themeMode == themeMode;
    final foregroundColor = selected
        ? Theme.of(context).colorScheme.onPrimaryFixed
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: Icon(_iconData, fill: 1),
      title: Text(_title),
      onTap: () => context.read<ThemeCubit>().setThemeMode(themeMode),
      iconColor: foregroundColor,
      tileColor: selected ? Theme.of(context).colorScheme.primaryFixed : null,
      titleTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: foregroundColor,
          ),
      trailing: selected
          ? const Icon(Symbols.check_circle_rounded, fill: 1)
          : const Icon(Symbols.circle_rounded),
    );
  }

  IconData get _iconData => switch (themeMode) {
        ThemeMode.system => Symbols.palette_rounded,
        ThemeMode.light => Symbols.light_mode_rounded,
        ThemeMode.dark => Symbols.dark_mode_rounded,
      };

  String get _title => switch (themeMode) {
        ThemeMode.system => 'Tema del sistema',
        ThemeMode.light => 'Tema claro',
        ThemeMode.dark => 'Tema oscuro',
      };
}
