import 'dart:async';

import 'package:aucorsa/about/widgets/about_button.dart';
import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_balance_view.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_options_dialog.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/urls.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BonobusDetailsView extends StatelessWidget {
  static const _helpUrls = {
    BonobusProvider.aucorsa: Urls.bonobusHelpAucorsa,
    BonobusProvider.consorcio: Urls.bonobusHelpConsorcio,
  };

  final Future<void> Function()? onRefresh;
  final VoidCallback? onViewMovements;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  const BonobusDetailsView({
    this.onRefresh,
    this.onViewMovements,
    this.onEdit,
    this.onDelete,
    super.key,
  });

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
        actions: const [AboutButton()],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        notificationPredicate: (_) => onRefresh != null,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              spacing: 40,
              children: [
                BonobusBalanceView(
                  balance: bonobusState.balance,
                  loading: bonobusState.status == BonobusStatus.loading,
                  lastUpdated: bonobusState.lastUpdated,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    spacing: 16,
                    children: [
                      if (bonobusState.provider == BonobusProvider.consorcio)
                        ListViewSection(
                          children: [
                            ListViewSectionTile(
                              leading: const Icon(Symbols.contactless_rounded),
                              title: Text(context.l10n.scanBonobusTitle),
                              subtitle: Text(
                                context.l10n.scanBonobusSubtitle,
                              ),
                            ),
                          ],
                        ),
                      ListViewSection(
                        children: [
                          ListViewSectionTile(
                            leading: const Icon(Symbols.credit_card_rounded),
                            title: Text(
                              bonobusState.name ?? getDefaultProviderName(),
                            ),
                            subtitle: Text(
                              bonobusState.id!,
                              style: GoogleFonts.robotoMono(
                                textStyle: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            onTap: () => showBonobusOptionsDialog(
                              context: context,
                              onEdit: onEdit,
                              onDelete:
                                  onDelete ??
                                  () async =>
                                      context.read<BonobusCubit>().reset(),
                            ),
                            trailing: Icon(
                              Symbols.chevron_right_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (bonobusState.provider ==
                                  BonobusProvider.aucorsa &&
                              onViewMovements != null)
                            ListViewSectionTile(
                              leading: const Icon(
                                Symbols.receipt_long_rounded,
                              ),
                              title: Text(
                                context.l10n.aucorsaCardMovements,
                              ),
                              subtitle: Text(
                                context.l10n.aucorsaCardMovementsSubtitle,
                              ),
                              onTap: onViewMovements,
                              trailing: Icon(
                                Symbols.chevron_right_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ListViewSectionTile(
                            leading: const Icon(Symbols.add_circle_rounded),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
