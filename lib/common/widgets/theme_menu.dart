import 'package:aucorsa/common/cubits/theme_cubit.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/widgets/aucorsa_menu.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:material_ui/material_ui.dart';

class ThemeMenu extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTheme = context.watch<ThemeCubit>().state;
    final colors = Theme.of(context).colorScheme;

    return AucorsaMenu(
      alignment: AlignmentDirectional.bottomEnd,
      menuChildren: [
        for (final themeMode in ThemeMode.values)
          Semantics(
            selected: themeMode == selectedTheme,
            child: MenuItemButton(
              onPressed: () => context.read<ThemeCubit>().setThemeMode(themeMode),
              style: themeMode == selectedTheme
                  ? ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(colors.primary),
                      foregroundColor: WidgetStatePropertyAll(colors.onPrimary),
                      iconColor: WidgetStatePropertyAll(colors.onPrimary),
                    )
                  : null,
              leadingIcon: Icon(switch (themeMode) {
                ThemeMode.system => Symbols.palette_rounded,
                ThemeMode.light => Symbols.light_mode_rounded,
                ThemeMode.dark => Symbols.dark_mode_rounded,
              }, fill: 1),
              child: Text(switch (themeMode) {
                ThemeMode.system => context.l10n.systemTheme,
                ThemeMode.light => context.l10n.lightTheme,
                ThemeMode.dark => context.l10n.darkTheme,
              }),
            ),
          ),
      ],
      builder: (context, toggleMenu) => ListViewSectionTile(
        leading: const Icon(Symbols.palette_rounded),
        title: Text(context.l10n.appearanceTitle),
        subtitle: Text(context.l10n.appearanceSubtitle),
        onTap: toggleMenu,
      ),
    );
  }
}
