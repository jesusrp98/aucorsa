import 'package:aucorsa/about/widgets/about_button.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/aucorsa_theme.dart';
import 'package:aucorsa/common/utils/bus_line_utils.dart';
import 'package:aucorsa/common/widgets/bus_stop_list_view.dart';
import 'package:flutter/material.dart';

class BusLinePage extends StatelessWidget {
  static const path = '/bus-line';

  final String lineId;

  const BusLinePage({required this.lineId, super.key});

  @override
  Widget build(BuildContext context) {
    final line = BusLineUtils.getLine(lineId);

    return Theme(
      data: AucorsaTheme.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: line.color,
          brightness: Theme.of(context).brightness,
        ),
      ),
      child: Builder(
        builder: (context) => Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar.medium(
                title: Text(
                  context.l10n.busLine(line.id),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                actions: const [AboutButton()],
              ),
              BusStopListView(stopIds: line.stops),
            ],
          ),
        ),
      ),
    );
  }
}
