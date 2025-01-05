import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/favorite_stops/cubits/favorite_stops_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class HomePage extends StatefulWidget {
  static const path = '/';

  final Widget child;

  const HomePage({
    required this.child,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final destinations = {
    '/favorite-stops': NavigationDestination(
      icon: const Icon(Symbols.favorite_rounded),
      selectedIcon: const Icon(Symbols.favorite_rounded, fill: 1),
      label: context.l10n.favoritesPageTitle,
    ),
    '/bus-lines': NavigationDestination(
      icon: const Icon(Symbols.format_list_bulleted_rounded),
      selectedIcon: const Icon(Symbols.format_list_bulleted_rounded, fill: 1),
      label: context.l10n.busLines,
    ),
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<FavoriteStopsCubit>().state.isEmpty) {
        context.go(destinations.keys.elementAt(1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: SizedBox(
        height: 72 + MediaQuery.of(context).padding.bottom,
        child: NavigationBar(
          destinations: destinations.values.toList(),
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(context, index),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) =>
      destinations.keys.toList().indexOf(GoRouterState.of(context).uri.path);

  void _onItemTapped(BuildContext context, int index) =>
      context.go(destinations.keys.elementAt(index));
}
