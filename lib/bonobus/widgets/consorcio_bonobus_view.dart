import 'package:aucorsa/bonobus/widgets/bonobus_details_view.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_scan_controller.dart';
import 'package:material_ui/material_ui.dart';

class ConsorcioBonobusView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [BonobusScanController(), BonobusDetailsView()],
    );
  }
}
