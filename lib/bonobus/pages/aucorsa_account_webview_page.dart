import 'dart:async';

import 'package:aucorsa/common/utils/app_localizations_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class AucorsaAccountWebViewPage extends StatefulWidget {
  final String initialUrl;
  final bool finishWhenAuthenticated;

  const AucorsaAccountWebViewPage({
    required this.initialUrl,
    required this.finishWhenAuthenticated,
    super.key,
  });

  @override
  State<AucorsaAccountWebViewPage> createState() =>
      _AucorsaAccountWebViewPageState();
}

class _AucorsaAccountWebViewPageState extends State<AucorsaAccountWebViewPage> {
  static const _authenticationHandler = 'aucorsaAuthenticationSucceeded';

  double progress = 0;
  bool completing = false;
  bool checkingAuthentication = false;
  Timer? authenticationPoller;

  Future<void> _finishAuthentication(WebUri? url) async {
    if (!widget.finishWhenAuthenticated || completing || url == null) return;
    final authenticatedPath =
        url.path.startsWith('/mis-tarjetas') ||
        url.path.startsWith('/mi-cuenta');
    final isAucorsa = url.host == 'aucorsa.es' || url.host == 'www.aucorsa.es';
    if (!isAucorsa || !authenticatedPath) return;

    await _completeAuthentication();
  }

  Future<void> _completeAuthentication() async {
    if (!widget.finishWhenAuthenticated || completing) return;
    completing = true;
    authenticationPoller?.cancel();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await CookieManager.instance().flush();
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _startAuthenticationPolling(InAppWebViewController controller) {
    if (!widget.finishWhenAuthenticated || completing) return;
    authenticationPoller?.cancel();
    authenticationPoller = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => unawaited(_checkAuthenticationText(controller)),
    );
    unawaited(_checkAuthenticationText(controller));
  }

  Future<void> _checkAuthenticationText(
    InAppWebViewController controller,
  ) async {
    if (checkingAuthentication || completing || !mounted) return;
    checkingAuthentication = true;
    try {
      final result = await controller.evaluateJavascript(
        source: r'''
(() => {
  const text = document.body?.innerText ?? '';
  return text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .split(/\n+/)
    .map(line => line.trim().toLowerCase().replace(/[\u00a1!.,:]/g, ''))
    .some(line => line === 'exito');
})();
''',
      );
      if (result == true || result == 1 || result == 'true') {
        await _completeAuthentication();
      }
    } catch (_) {
      // A navigation can temporarily make the JavaScript context unavailable.
    } finally {
      checkingAuthentication = false;
    }
  }

  Future<void> _watchForAuthentication(
    InAppWebViewController controller,
  ) async {
    if (!widget.finishWhenAuthenticated || completing) return;

    await controller.evaluateJavascript(
      source: r'''
(() => {
  const observerKey = '__aucorsaAuthenticationObserver';
  window[observerKey]?.disconnect();

  let notified = false;
  const hasSuccessMessage = () => {
    const text = document.body?.innerText ?? '';
    return text
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .split(/\n+/)
      .map(line => line.trim().toLowerCase().replace(/[\u00a1!.,:]/g, ''))
      .some(line => line === 'exito');
  };
  const notifyIfAuthenticated = () => {
    if (notified || !hasSuccessMessage()) return;
    notified = true;
    window[observerKey]?.disconnect();
    window.flutter_inappwebview.callHandler('aucorsaAuthenticationSucceeded');
  };

  notifyIfAuthenticated();
  if (notified || !document.body) return;

  window[observerKey] = new MutationObserver(notifyIfAuthenticated);
  window[observerKey].observe(document.body, {
    childList: true,
    subtree: true,
    characterData: true,
  });
})();
''',
    );
  }

  Future<NavigationActionPolicy> _handleNavigation(
    NavigationAction action,
  ) async {
    final url = action.request.url;
    if (url == null) return NavigationActionPolicy.CANCEL;

    final isAucorsa =
        url.scheme == 'https' &&
        (url.host == 'aucorsa.es' || url.host == 'www.aucorsa.es');
    if (isAucorsa) return NavigationActionPolicy.ALLOW;

    final uri = Uri.parse(url.toString());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return NavigationActionPolicy.CANCEL;
  }

  @override
  void dispose() {
    authenticationPoller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.finishWhenAuthenticated
              ? context.l10n.aucorsaAccountAccess
              : context.l10n.aucorsaManageCards,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (progress < 1) LinearProgressIndicator(value: progress),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(widget.initialUrl),
                ),
                initialSettings: InAppWebViewSettings(
                  useShouldOverrideUrlLoading: true,
                ),
                onWebViewCreated: (controller) {
                  controller.addJavaScriptHandler(
                    handlerName: _authenticationHandler,
                    callback: (_) {
                      unawaited(_completeAuthentication());
                      return null;
                    },
                  );
                },
                shouldOverrideUrlLoading: (_, action) =>
                    _handleNavigation(action),
                onLoadStart: (_, _) => setState(() => progress = 0),
                onProgressChanged: (_, value) {
                  if (!mounted) return;
                  setState(() => progress = value / 100);
                },
                onLoadStop: (controller, url) async {
                  await _finishAuthentication(url);
                  if (!mounted || completing) return;
                  await _watchForAuthentication(controller);
                  _startAuthenticationPolling(controller);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
