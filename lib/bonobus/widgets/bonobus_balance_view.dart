import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/date_time_extension.dart';
import 'package:aucorsa/common/widgets/aucorsa_shimmer.dart';
import 'package:flutter/material.dart';

class BonobusBalanceView extends StatelessWidget {
  final String? balance;
  final bool loading;
  final DateTime? lastUpdated;

  const BonobusBalanceView({
    required this.balance,
    this.loading = false,
    this.lastUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24).copyWith(bottom: 16),
          child: ClipPath(
            clipper: const ShapeBorderClipper(shape: StadiumBorder()),
            child: Stack(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  width: 256,
                  height: 112,
                  alignment: Alignment.center,
                  child: Text(
                    balance ?? '',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (loading)
                  Positioned.fill(
                    child: AucorsaShimmer(
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: .6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (lastUpdated != null)
          Text(
            context.l10n.lastUpdated(lastUpdated!.shortDateTimeLabel),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
