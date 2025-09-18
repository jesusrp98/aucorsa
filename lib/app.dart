import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/common/cubits/bus_service_cubit.dart';
import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/cubits/theme_cubit.dart';
import 'package:aucorsa/common/utils/aucorsa_router.dart';
import 'package:aucorsa/common/utils/aucorsa_theme.dart';
import 'package:aucorsa/l10n/app_localizations.dart';
import 'package:aucorsa/stops/cubits/bus_line_selector_cubit.dart';
import 'package:aucorsa/stops/cubits/favorite_stops_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AucorsaApp extends StatelessWidget {
  static final router = AucorsaRouter.initialize();

  const AucorsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => BusServiceCubit()),
        BlocProvider(create: (_) => FavoriteStopsCubit()),
        const BlocProvider(create: BusLineSelectorCubit.new),
        BlocProvider(create: (_) => BusStopCustomDataCubit()),
        BlocProvider(create: (_) => BonobusCubit()),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'Aucorsa GO!',
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: context.watch<ThemeCubit>().state,
          theme: AucorsaTheme.from(
            colorScheme: AucorsaTheme.defaultLightColorScheme,
          ),
          darkTheme: AucorsaTheme.from(
            colorScheme: AucorsaTheme.defaultDarkColorScheme,
          ),
        ),
      ),
    );
  }
}
