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
              const _AboutSectionTitle('Ajustes'),
              _AboutSectionTile(
                leading: const Icon(Symbols.palette_rounded),
                title: const Text('Apariencia'),
                subtitle: const Text('Elige entre luz y oscuridad'),
                onTap: () => showThemeBottomSheet(context),
              ),
              const _AboutSectionTitle('Información'),
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
                title: const Text('Creado por Chechu Rodríguez'),
                subtitle: const Text('Aplicaciones libres bien diseñadas'),
                onTap: () => launchUrlString(Urls.authorProfile),
              ),
              _AboutSectionTile(
                leading: const Icon(Symbols.email_rounded),
                title: const Text('Envíame un correo'),
                subtitle: const Text('Reporta fallos o solicita funciones'),
                onTap: () => launchUrlString(Urls.emailUrl),
              ),
              const Divider(),
              _AboutSectionTile(
                title: const Text('Datos proporcionados por AUCORSA'),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => const _DataOriginBottomSheet(),
                ),
              ),
              _AboutSectionTile(
                title: const Text('Licencias de software libre'),
                onTap: () => showLicensePage(context: context),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Versión ${_packageInfo?.version} (${_packageInfo?.buildNumber})',
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
            '''
Esta aplicación no está afiliada ni es la aplicación oficial desarrollada por AUCORSA. Toda la información relacionada con las líneas de autobuses, los recorridos, las paradas y los tiempos de paso es proporcionada por AUCORSA, la empresa responsable del transporte público urbano.

El objetivo principal de esta aplicación es facilitar el acceso a la información pública de manera más intuitiva y accesible para los usuarios, mejorando así la experiencia de quienes utilizan los servicios de transporte público. Buscamos contribuir al fomento de una movilidad sostenible y eficiente al brindar herramientas que promuevan el uso del transporte colectivo como una alternativa cómoda y responsable para la movilidad urbana.

Esta iniciativa independiente se compromete a ofrecer datos precisos y actualizados, aunque es importante tener en cuenta que la fuente original de toda la información es AUCORSA. Recomendamos siempre contrastar los datos con los canales oficiales para garantizar la máxima precisión.''',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.justify,
          ),
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
