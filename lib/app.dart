import 'package:aucorsa/common/cubits/bus_service_cubit.dart';
import 'package:aucorsa/common/utils/aucorsa_router.dart';
import 'package:aucorsa/common/utils/aucorsa_theme.dart';
import 'package:aucorsa/favorite_stops/cubits/favorite_stops_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AucorsaApp extends StatelessWidget {
  static final router = AucorsaRouter.initialize();

  const AucorsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => BusServiceCubit()),
        BlocProvider(create: (_) => FavoriteStopsCubit()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: AucorsaTheme.from(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
          ),
        ),
        darkTheme: AucorsaTheme.from(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
        ),
      ),
    );
  }
}
