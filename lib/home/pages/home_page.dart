import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class HomePage extends StatelessWidget {
  static const path = '/';

  static const destinations = {
    '/favorite-stops': NavigationDestination(
      icon: Icon(Symbols.favorite_rounded),
      selectedIcon: Icon(Symbols.favorite_rounded, fill: 1),
      label: 'Favoritos',
    ),
    '/bus-lines': NavigationDestination(
      icon: Icon(Symbols.format_list_bulleted_rounded),
      selectedIcon: Icon(Symbols.format_list_bulleted_rounded, fill: 1),
      label: 'Líneas',
    ),
  };

  final Widget child;

  const HomePage({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
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

  static int _calculateSelectedIndex(BuildContext context) =>
      destinations.keys.toList().indexOf(GoRouterState.of(context).uri.path);

  void _onItemTapped(BuildContext context, int index) =>
      context.go(destinations.keys.elementAt(index));
}
