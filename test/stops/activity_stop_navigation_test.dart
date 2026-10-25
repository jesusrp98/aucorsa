import 'package:aucorsa/bus_lines/pages/bus_lines_page.dart';
import 'package:aucorsa/common/cubits/bus_service_cubit.dart';
import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/models/bus_stop_line_estimation.dart';
import 'package:aucorsa/common/utils/aucorsa_router.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:aucorsa/common/widgets/bus_stop_tile.dart';
import 'package:aucorsa/common/widgets/lucky_navigation_bar.dart';
import 'package:aucorsa/l10n/app_localizations.dart';
import 'package:aucorsa/live_activity/live_activity_cubit.dart';
import 'package:aucorsa/stops/cubits/favorite_stops_cubit.dart';
import 'package:aucorsa/stops/pages/favorite_stops_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('cold favorite link expands in Favorites and can be collapsed', (
    tester,
  ) async {
    final router = await _launch(tester, favorites: [141, 56], stop: '141');

    _expectFavorites(tester, router);
    expect(find.byType(BottomSheet), findsNothing);
    expect(_refreshFor(141), findsOneWidget);
    expect(_refreshFor(56), findsNothing);

    await tester.tap(find.text(BusStopUtils.resolveName(141)));
    await tester.pumpAndSettle();
    expect(_refreshFor(141), findsNothing);

    await _openLink(tester, '141');
    expect(_refreshFor(141), findsOneWidget);
    _expectFavorites(tester, router);
  });

  testWidgets('warm link switches tabs and reveals a favorite below the fold', (
    tester,
  ) async {
    final favorites = [
      for (var id = 1; id <= 56; id++)
        if (BusStopUtils.resolveName(id).isNotEmpty) id,
    ];
    final router = await _launch(tester, favorites: favorites);
    router.go(BusLinesPages.path);
    await tester.pumpAndSettle();

    await _openLink(tester, '56');

    _expectFavorites(tester, router);
    expect(find.byType(BottomSheet), findsNothing);
    expect(_refreshFor(56), findsOneWidget);
    expect(
      find.text(BusStopUtils.resolveName(56)).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets(
    'non-favorite uses the map sheet without stacking repeated links',
    (tester) async {
      final router = await _launch(tester, favorites: [141], stop: '56');

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(tester.widget<BusStopTile>(_stop(56)).alwaysExpanded, isTrue);
      expect(_refreshFor(56), findsOneWidget);

      await _openLink(tester, '56');
      expect(find.byType(BottomSheet), findsOneWidget);

      // A different activity link replaces the sheet with the favorite card.
      await _openLink(tester, '141');
      expect(find.byType(BottomSheet), findsNothing);
      expect(_refreshFor(141), findsOneWidget);
      _expectFavorites(tester, router);
    },
  );

  testWidgets('cold link with no favorites keeps the stop sheet open', (
    tester,
  ) async {
    final router = await _launch(tester, favorites: [], stop: '56');

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(_refreshFor(56), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    _expectFavorites(tester, router);

    await _openLink(tester, '56');
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets(
    'invalid links stay in Favorites and report an unavailable stop',
    (tester) async {
      final router = await _launch(tester, favorites: [141], stop: 'invalid');

      _expectFavorites(tester, router);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(_refreshFor(141), findsNothing);

      await _openLink(tester, '999999');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    },
  );
}

Finder _stop(int id) => find.byWidgetPredicate(
  (widget) => widget is BusStopTile && widget.stopId == id,
);

Finder _refreshFor(int id) => find
    .descendant(of: _stop(id), matching: find.text('Refresh'))
    .hitTestable();

void _expectFavorites(WidgetTester tester, GoRouter router) {
  expect(find.byType(FavoriteStopsPage), findsOneWidget);
  expect(find.byType(BackButton), findsNothing);
  expect(router.state.uri.path, FavoriteStopsPage.path);
  expect(router.state.uri.queryParameters, isEmpty);
  expect(
    tester
        .widget<LuckyNavigationBar>(find.byType(LuckyNavigationBar))
        .selectedIndex,
    0,
  );
  expect(tester.takeException(), isNull);
}

Future<void> _openLink(WidgetTester tester, String stop) async {
  final router =
      tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
          as GoRouter;
  await router.routeInformationProvider.didPushRouteInformation(
    RouteInformation(uri: Uri.parse('aucorsa://app/stops/$stop')),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<GoRouter> _launch(
  WidgetTester tester, {
  required List<int> favorites,
  String? stop,
}) async {
  HydratedBloc.storage = _MemoryStorage();
  await tester.binding.setSurfaceSize(const Size(430, 932));
  final router = AucorsaRouter.initialize();
  if (stop != null) router.go('aucorsa://app/stops/$stop');
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<BusServiceCubit>(create: (_) => _BusService()),
        BlocProvider(
          create: (_) {
            final cubit = FavoriteStopsCubit();
            favorites.forEach(cubit.add);
            return cubit;
          },
        ),
        BlocProvider(create: (_) => BusStopCustomDataCubit()),
        BlocProvider(create: (_) => LiveActivityCubit()),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await tester.binding.setSurfaceSize(null);
  });
  return router;
}

class _BusService extends BusServiceCubit {
  @override
  Future<List<BusStopLineEstimation>> requestBusStopData(int stopId) async =>
      const [
        BusStopLineEstimation(lineId: '5', estimations: [Duration(minutes: 7)]),
      ];
}

class _MemoryStorage implements Storage {
  final _values = <String, dynamic>{};

  @override
  dynamic read(String key) => _values[key];

  @override
  Future<void> write(String key, dynamic value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<void> close() async {}
}
