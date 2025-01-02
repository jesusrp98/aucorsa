import 'dart:async';

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
  late PackageInfo _packageInfo;

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
          const SliverAppBar.medium(
            title: Text(
              'Aucorsa GO!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          SliverList.list(
            children: [
              const _AboutSectionTitle('Ajustes'),
              _AboutSectionTile(
                leading: const Icon(Symbols.palette_rounded),
                title: const Text('Apariencia'),
                subtitle: const Text('Elige entre luz y oscuridad'),
                onTap: () => showThemeBottomSheet(context),
              ),
              const _AboutSectionTitle('Información'),
              _AboutSectionTile(
                leading: const Icon(Symbols.info_rounded),
                title: Text('Versión ${_packageInfo.version}'),
                subtitle: const Text(
                  'Échale un vistazo a la lista de cambios',
                ),
                onTap: () => launchUrlString(Urls.changelog),
              ),
              _AboutSectionTile(
                leading: const Icon(Symbols.star_rounded),
                title: const Text('¿Disfrutando de la app?'),
                subtitle: const Text('Deja tu reseña en la tienda'),
                onTap: () async {
                  final inAppReview = InAppReview.instance;
                  if (await inAppReview.isAvailable()) {
                    unawaited(inAppReview.requestReview());
                  }
                },
              ),
              _AboutSectionTile(
                leading: const Icon(Symbols.public_rounded),
                title: const Text('Esto es software libre'),
                subtitle: const Text('Código fuente disponible para todos'),
                onTap: () => launchUrlString(Urls.appSource),
              ),
              _AboutSectionTile(
                leading: const Icon(Symbols.account_circle_rounded),
                title: const Text('Creado por Chechu Rodriguez'),
                subtitle: const Text('Aplicaciones libres bien diseñadas'),
                onTap: () => launchUrlString(Urls.authorProfile),
              ),
              _AboutSectionTile(
                leading: const Icon(Symbols.email_rounded),
                title: const Text('Envíame un correo'),
                subtitle: const Text('Reporta fallos o solicita funciones'),
                onTap: () => launchUrlString(Urls.emailUrl),
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
      subtitle: subtitle,
      subtitleTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      trailing: const Icon(Symbols.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
