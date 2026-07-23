import 'dart:async';

import 'package:aucorsa/bonobus/cubits/aucorsa_cards_cubit.dart';
import 'package:aucorsa/bonobus/pages/aucorsa_account_webview_page.dart';
import 'package:aucorsa/bonobus/repositories/aucorsa_card_repository.dart';
import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/urls.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:aucorsa/common/widgets/theme_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AboutPage extends StatefulWidget {
  static const path = '/about';

  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _packageInfo;
  late final AucorsaCardRepository _aucorsaRepository;
  late final AucorsaCardsCubit _aucorsaCardsCubit;

  @override
  void initState() {
    super.initState();

    _aucorsaRepository = AucorsaCardRepository();
    _aucorsaCardsCubit = AucorsaCardsCubit(_aucorsaRepository);
    unawaited(_aucorsaCardsCubit.load());
    unawaited(_initPackageInfo());
  }

  @override
  void dispose() {
    unawaited(_aucorsaCardsCubit.close());
    _aucorsaRepository.close();
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;
    return setState(() => _packageInfo = info);
  }

  Future<void> _signIn() async {
    final authenticated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AucorsaAccountWebViewPage(
          initialUrl: AucorsaCardRepository.signInUrl,
          finishWhenAuthenticated: true,
        ),
      ),
    );
    if (!mounted || authenticated != true) return;
    await _aucorsaCardsCubit.load();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.aucorsaDisconnectTitle),
        content: Text(context.l10n.aucorsaDisconnectSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.aucorsaDisconnect),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await _aucorsaCardsCubit.logout();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _aucorsaCardsCubit,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              title: Text(
                context.l10n.appName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16).copyWith(top: 0),
              sliver: SliverList.list(
                children: [
                  BlocBuilder<AucorsaCardsCubit, AucorsaCardsState>(
                    builder: (context, state) => _AucorsaAccountSection(
                      state: state,
                      onSignIn: () => unawaited(_signIn()),
                      onSignOut: () => unawaited(_signOut()),
                      onRetry: () => unawaited(_aucorsaCardsCubit.load()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListViewSection(
                    children: [
                      ListViewSectionTile(
                        leading: const Icon(Symbols.palette_rounded),
                        title: Text(context.l10n.appearanceTitle),
                        subtitle: Text(context.l10n.appearanceSubtitle),
                        onTap: () => showThemeBottomSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListViewSection(
                    children: [
                      ListViewSectionTile(
                        leading: const Icon(Symbols.star_rounded),
                        title: Text(context.l10n.ratingTitle),
                        subtitle: Text(context.l10n.ratingSubtitle),
                        onTap: () async {
                          final inAppReview = InAppReview.instance;
                          if (await inAppReview.isAvailable()) {
                            unawaited(inAppReview.requestReview());
                          }
                        },
                      ),
                      ListViewSectionTile(
                        leading: const Icon(Symbols.public_rounded),
                        title: Text(context.l10n.freeSoftwareTitle),
                        subtitle: Text(context.l10n.freeSoftwareSubtitle),
                        onTap: () => launchUrlString(Urls.appSource),
                      ),
                      ListViewSectionTile(
                        leading: const Icon(Symbols.design_services_rounded),
                        title: Text(context.l10n.authorTitle),
                        subtitle: Text(context.l10n.authorSubtitle),
                        onTap: () => launchUrlString(Urls.authorProfile),
                      ),
                      ListViewSectionTile(
                        leading: const Icon(Symbols.email_rounded),
                        title: Text(context.l10n.emailTitle),
                        subtitle: Text(context.l10n.emailSubtitle),
                        onTap: () => launchUrlString(Urls.emailUrl),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListViewSection(
                    children: [
                      ListViewSectionTile(
                        title: Text(context.l10n.dataOriginTitle),
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => const _DataOriginBottomSheet(),
                        ),
                      ),
                      ListViewSectionTile(
                        title: Text(context.l10n.licenseTitle),
                        onTap: () => showLicensePage(context: context),
                      ),
                    ],
                  ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.all(16),
                    child: Text(
                      context.l10n.versionTitle(
                        _packageInfo?.version ?? '',
                        _packageInfo?.buildNumber ?? '',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AucorsaAccountSection extends StatelessWidget {
  final AucorsaCardsState state;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onRetry;

  const _AucorsaAccountSection({
    required this.state,
    required this.onSignIn,
    required this.onSignOut,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final loading =
        state.status == AucorsaCardsStatus.initial ||
        state.status == AucorsaCardsStatus.loading;
    final authenticated = state.status == AucorsaCardsStatus.authenticated;
    final failed = state.status == AucorsaCardsStatus.failure;

    return ListViewSection(
      children: [
        ListViewSectionTile(
          leading: const Icon(Symbols.account_circle_rounded),
          title: Text(context.l10n.aucorsaAccountAccess),
          subtitle: Text(
            failed
                ? context.l10n.aucorsaDataError
                : authenticated
                ? context.l10n.aucorsaDisconnect
                : context.l10n.aucorsaSignIn,
          ),
          trailing: loading
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  failed
                      ? Symbols.refresh_rounded
                      : authenticated
                      ? Symbols.logout_rounded
                      : Symbols.login_rounded,
                ),
          onTap: loading
              ? null
              : failed
              ? onRetry
              : authenticated
              ? onSignOut
              : onSignIn,
        ),
      ],
    );
  }
}

class _DataOriginBottomSheet extends StatelessWidget {
  const _DataOriginBottomSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16).copyWith(top: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            context.l10n.dataOriginSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.justify,
          ),
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }
}
