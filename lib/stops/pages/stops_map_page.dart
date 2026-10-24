import 'package:aucorsa/stops/map/widgets/aucorsa_map.dart';
import 'package:material_ui/material_ui.dart';

class StopsMapPage extends StatelessWidget {
  static const path = '/stops-map';

  const new({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: AucorsaMap());
}
