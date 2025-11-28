import 'dart:async';

import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/urls.dart';
import 'package:aucorsa/common/widgets/list_view_section.dart';
import 'package:aucorsa/common/widgets/theme_bottom_sheet.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();

    unawaited(_initPackageInfo());
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();

    return setState(() => _packageInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      leading: const Icon(Symbols.account_circle_rounded),
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
