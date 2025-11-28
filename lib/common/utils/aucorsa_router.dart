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
import 'package:go_transitions/go_transitions.dart';

class AucorsaRouter {
  const AucorsaRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );
  static final _shellNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'shell',
  );

  static GoRouter initialize() {
    GoTransition.defaultCurve = Curves.easeInOutCubic;
    GoTransition.defaultDuration = const Duration(milliseconds: 100);

    return GoRouter(
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
              builder: (_, _) => const FavoriteStopsPage(),
              pageBuilder: GoTransitions.fade.call,
            ),
            GoRoute(
              path: BonobusPage.path,
              builder: (_, _) => const BonobusPage(),
              pageBuilder: GoTransitions.fade.call,
            ),
            GoRoute(
              path: StopsMapPage.path,
              builder: (_, _) => const StopsMapPage(),
              pageBuilder: GoTransitions.fade.call,
            ),
            GoRoute(
              path: BusLinesPages.path,
              builder: (_, _) => const BusLinesPages(),
              pageBuilder: GoTransitions.fade.call,
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
}
