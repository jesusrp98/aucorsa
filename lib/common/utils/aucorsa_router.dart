import 'package:aucorsa/bus_lines/pages/bus_line_page.dart';
import 'package:aucorsa/bus_lines/pages/bus_lines_page.dart';
import 'package:aucorsa/favorite_stops/pages/favorite_stops_page.dart';
import 'package:aucorsa/home/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AucorsaRouter {
  const AucorsaRouter._();

  static final _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static GoRouter initialize() => GoRouter(
        initialLocation: FavoriteStopsPage.path,
        navigatorKey: _rootNavigatorKey,
        routes: [
          ShellRoute(
            navigatorKey: _shellNavigatorKey,
            builder: (context, state, child) => HomePage(child: child),
            routes: [
              GoRoute(
                path: FavoriteStopsPage.path,
                pageBuilder: (context, state) => const MaterialPage(
                  child: FavoriteStopsPage(),
                ),
              ),
              GoRoute(
                path: BusLinesPages.path,
                pageBuilder: (context, state) => const MaterialPage(
                  child: BusLinesPages(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: BusLinePage.path,
            builder: (context, state) => BusLinePage(
              lineId: state.extra! as String,
            ),
          ),
        ],
      );
}
