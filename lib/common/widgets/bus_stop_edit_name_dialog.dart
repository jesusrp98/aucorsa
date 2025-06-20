import 'package:aucorsa/common/cubits/bus_stop_custom_data_cubit.dart';
import 'package:aucorsa/common/utils/bus_stop_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

Future<void> showBusStopEditNameDialog(
  BuildContext context, {
  required int stopId,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _BusStopEditNameDialog(stopId),
);

class _BusStopEditNameDialog extends StatefulWidget {
  final int stopId;

  const _BusStopEditNameDialog(this.stopId);

  @override
  State<_BusStopEditNameDialog> createState() => _BusStopEditNameDialogState();
}

class _BusStopEditNameDialogState extends State<_BusStopEditNameDialog> {
  late final TextEditingController _nameController;
  late final baseStopName = BusStopUtils.resolveName(widget.stopId);

  late int? _selectedIcon;

  final List<IconData> _iconOptions = [
    Symbols.home,
    Symbols.school,
    Symbols.work,
    Symbols.flag,
    Symbols.sports_soccer,
    Symbols.music_note,
    Symbols.location_on,
    Symbols.local_hospital,
    Symbols.balance,
    Symbols.favorite,
    Symbols.bolt,
    Symbols.group,
    Symbols.construction,
    Symbols.park,
    Symbols.train,
    Symbols.travel,
    Symbols.directions_car,
    Symbols.directions_boat,
  ];

  @override
  void initState() {
    super.initState();

    final initialData = context.read<BusStopCustomDataCubit>().get(
      widget.stopId,
    );

    _nameController = TextEditingController(text: initialData?.name)
      ..addListener(() => setState(() {}));

    _selectedIcon = initialData?.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ).copyWith(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: baseStopName,
                  suffixIcon: _nameController.value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Symbols.clear_rounded),
                          onPressed: _nameController.clear,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final icon in _iconOptions)
                    ChoiceChip(
                      showCheckmark: false,
                      selectedColor: Theme.of(context).colorScheme.primaryFixed,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      side: BorderSide.none,
                      label: Icon(
                        IconDataRounded(icon.codePoint),
                        fill: 1,
                        color: _selectedIcon == icon.codePoint
                            ? Theme.of(context).colorScheme.onPrimaryFixed
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      selected: _selectedIcon == icon.codePoint,
                      onSelected: (_) => setState(() {
                        _selectedIcon = _selectedIcon == icon.codePoint
                            ? null
                            : icon.codePoint;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(56),
                    textStyle: Theme.of(context).textTheme.titleMedium,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    context.read<BusStopCustomDataCubit>().set(
                      stopId: widget.stopId,
                      name: _nameController.text,
                      icon: _selectedIcon,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    MaterialLocalizations.of(context).saveButtonLabel,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(56),
                    textStyle: Theme.of(context).textTheme.titleMedium,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  onPressed: Navigator.of(context).pop,
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
