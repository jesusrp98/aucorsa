import 'package:aucorsa/about/widgets/about_button.dart';
import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_delete_dialog.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/urls.dart';
import 'package:aucorsa/common/widgets/aucorsa_shimmer.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BonobusDetailsView extends StatelessWidget {
  static const _helpUrls = {
    BonobusProvider.aucorsa: Urls.bonobusHelpAucorsa,
    BonobusProvider.consorcio: Urls.bonobusHelpConsorcio,
  };

  const BonobusDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final bonobusState = context.watch<BonobusCubit>().state;

    String getDefaultProviderName() {
      return switch (bonobusState.provider) {
        BonobusProvider.aucorsa => context.l10n.aucorsa,
        BonobusProvider.consorcio => context.l10n.consorcio,
        null => '',
      };
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(
          context.l10n.bonobus,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: const [
          AboutButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            spacing: 40,
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24).copyWith(bottom: 16),
                    child: ClipPath(
                      clipper: const ShapeBorderClipper(shape: StadiumBorder()),
                      child: Stack(
                        children: [
                          Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 24,
                            ),
                            width: 256,
                            height: 112,
                            alignment: Alignment.center,
                            child: Text(
                              bonobusState.balance != null
                                  ? bonobusState.balance.toString()
                                  : '',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                          if (bonobusState.status == BonobusStatus.loading)
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
                  if (bonobusState.lastUpdated != null)
                    Text(
                      context.l10n.lastUpdated(
                        DateFormat.MMMd()
                            .addPattern('jm', ', ')
                            .format(bonobusState.lastUpdated!),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  spacing: 16,
                  children: [
                    if (bonobusState.provider == BonobusProvider.consorcio)
                      ListViewSection(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            leading: SizedBox.square(
                              dimension: 40,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                                ),
                                child: Icon(
                                  Symbols.contactless_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            title: Text(context.l10n.scanBonobusTitle),
                            subtitle: Text(
                              context.l10n.scanBonobusSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ListViewSection(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: SizedBox.square(
                            dimension: 40,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                              ),
                              child: Icon(
                                Symbols.credit_card_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            bonobusState.name ?? getDefaultProviderName(),
                          ),
                          subtitle: Text(
                            bonobusState.id!,
                            style: bonobusState.id != null
                                ? GoogleFonts.robotoMono(
                                    textStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: SizedBox.square(
                            dimension: 40,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                              ),
                              child: Icon(
                                Symbols.add_circle,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          title: Text(context.l10n.topUpBonobusTitle),
                          subtitle: Text(
                            context.l10n.topUpBonobusSubtitle,
                          ),
                          onTap: () => launchUrlString(
                            _helpUrls[bonobusState.provider!]!,
                          ),
                          trailing: Icon(
                            Symbols.chevron_right_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: SizedBox.square(
                            dimension: 40,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                              ),
                              child: Icon(
                                Symbols.delete_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          title: Text(context.l10n.deleteBonobusTitle),
                          subtitle: Text(
                            context.l10n.deleteBonobusSubtitle,
                          ),
                          onTap: () => showBonobusDeleteDialog(
                            context: context,
                            onDelete: context.read<BonobusCubit>().reset,
                          ),
                          trailing: Icon(
                            Symbols.chevron_right_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
