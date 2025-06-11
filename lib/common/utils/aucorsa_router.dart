import 'package:aucorsa/about/pages/about_page.dart';
import 'package:aucorsa/bonobus/pages/bonobus_page.dart';
import 'package:aucorsa/bus_lines/pages/bus_line_map_page.dart';
import 'package:aucorsa/bus_lines/pages/bus_line_page.dart';
import 'package:aucorsa/bus_lines/pages/bus_lines_page.dart';
import 'package:aucorsa/home/pages/home_page.dart';
import 'package:aucorsa/stops/pages/favorite_stops_page.dart';
import 'package:aucorsa/stops/pages/stops_map_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AucorsaRouter {
  const AucorsaRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );
  static final _shellNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'shell',
  );

  static GoRouter initialize() => GoRouter(
    initialLocation: FavoriteStopsPage.path,
    navigatorKey: _rootNavigatorKey,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            HomePage(state: state, child: child),
        routes: [
          GoRoute(
            path: FavoriteStopsPage.path,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              name: state.name,
              child: const FavoriteStopsPage(),
            ),
          ),
          GoRoute(
            path: BonobusPage.path,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              name: state.name,
              child: const BonobusPage(),
            ),
          ),
          GoRoute(
            path: StopsMapPage.path,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              name: state.name,
              child: const StopsMapPage(),
            ),
          ),
          GoRoute(
            path: BusLinesPages.path,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              name: state.name,
              child: const BusLinesPages(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: BusLinePage.path,
        builder: (context, state) =>
            BusLinePage(lineId: state.extra! as String),
      ),
      GoRoute(
        path: AboutPage.path,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: BusLineMapPage.path,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: BusLineMapPage(lineId: state.extra! as String),
        ),
      ),
    ],
  );
}
