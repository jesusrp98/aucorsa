import 'dart:async';

import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:aucorsa/common/utils/urls.dart';
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

    _initPackageInfo();
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
              _packageInfo?.appName ?? '',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          SliverList.list(
            children: [
              _AboutSectionTitle(context.l10n.settings),
              _AboutSectionTile(
                leading: const Icon(Symbols.palette_rounded),
                title: Text(context.l10n.appearanceTitle),
                subtitle: Text(context.l10n.appearanceSubtitle),
                onTap: () => showThemeBottomSheet(context),
              ),
              _AboutSectionTitle(context.l10n.info),
              _AboutSectionTile(
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
              _AboutSectionTile(
                leading: const Icon(Symbols.public_rounded),
                title: Text(context.l10n.freeSoftwareTitle),
                subtitle: Text(context.l10n.freeSoftwareSubtitle),
                onTap: () => launchUrlString(Urls.appSource),
              ),
              _AboutSectionTile(
                leading: const Icon(Symbols.account_circle_rounded),
                title: Text(context.l10n.authorTitle),
                subtitle: Text(context.l10n.authorSubtitle),
                onTap: () => launchUrlString(Urls.authorProfile),
              ),
              _AboutSectionTile(
                leading: const Icon(Symbols.email_rounded),
                title: Text(context.l10n.emailTitle),
                subtitle: Text(context.l10n.emailSubtitle),
                onTap: () => launchUrlString(Urls.emailUrl),
              ),
              const Divider(),
              _AboutSectionTile(
                title: Text(context.l10n.dataOriginTitle),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => const _DataOriginBottomSheet(),
                ),
              ),
              _AboutSectionTile(
                title: Text(context.l10n.licenseTitle),
                onTap: () => showLicensePage(context: context),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
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
        ],
      ),
    );
  }
}

class _AboutSectionTitle extends StatelessWidget {
  final String data;

  const _AboutSectionTitle(this.data);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8).copyWith(left: 16),
      child: Text(
        data,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _AboutSectionTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final VoidCallback? onTap;

  const _AboutSectionTile({
    this.leading,
    this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading != null
          ? IconTheme.merge(
              data: const IconThemeData(size: 40),
              child: leading!,
            )
          : null,
      title: title,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      subtitle: subtitle,
      subtitleTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      trailing: const Icon(Symbols.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _DataOriginBottomSheet extends StatelessWidget {
  const _DataOriginBottomSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16).copyWith(top: 0),
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
