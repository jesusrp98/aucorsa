import 'package:aucorsa/about/pages/about_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class AboutButton extends StatelessWidget {
  const AboutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      onPressed: () => context.push(AboutPage.path),
      icon: Icon(
        _isCupertino(context) ? Symbols.pending : Symbols.more_vert,
      ),
    );
  }

  // Code extracted from Flutter's [PlatformAdaptiveIcons] widget
  bool _isCupertino(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
    }
  }
}
