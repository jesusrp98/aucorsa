import 'package:aucorsa/common/cubits/bus_service_cubit.dart';
import 'package:aucorsa/common/cubits/theme_cubit.dart';
import 'package:aucorsa/common/utils/aucorsa_router.dart';
import 'package:aucorsa/common/utils/aucorsa_theme.dart';
import 'package:aucorsa/favorite_stops/cubits/favorite_stops_cubit.dart';
import 'package:dynamic_color/dynamic_color.dart';
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
      ],
      child: Builder(
        builder: (context) => DynamicColorBuilder(
          builder: (light, dark) {
            final themeState = context.watch<ThemeCubit>().state;

            return MaterialApp.router(
              title: 'Aucorsa GO!',
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              themeMode: themeState.themeMode,
              theme: AucorsaTheme.from(
                colorScheme: _resolveColorScheme(
                  light,
                  AucorsaTheme.defaultLightColorScheme,
                  themeState.useDeviceTint,
                ),
              ),
              darkTheme: AucorsaTheme.from(
                colorScheme: _resolveColorScheme(
                  dark,
                  AucorsaTheme.defaultDarkColorScheme,
                  themeState.useDeviceTint,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  ColorScheme _resolveColorScheme(
    ColorScheme? tinteDcolorScheme,
    ColorScheme defaultColorScheme,
    bool useDeviceTint,
  ) =>
      useDeviceTint && tinteDcolorScheme != null
          ? tinteDcolorScheme
          : defaultColorScheme;
}
