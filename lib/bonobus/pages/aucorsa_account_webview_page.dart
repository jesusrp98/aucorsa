import 'dart:async';

import 'package:aucorsa/bonobus/utils/aucorsa_api.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Signs the user in to their AUCORSA account, popping with `true` once the
/// site lands on the account area.
class AucorsaAccountWebViewPage extends StatefulWidget {
  static const path = '/aucorsa-account';

  const AucorsaAccountWebViewPage({super.key});

  @override
  State<AucorsaAccountWebViewPage> createState() =>
      _AucorsaAccountWebViewPageState();
}

class _AucorsaAccountWebViewPageState extends State<AucorsaAccountWebViewPage> {
  static const _authenticationHandler = 'aucorsaAuthenticationSucceeded';

  double progress = 0;
  bool completing = false;

  Future<void> _finishAuthentication(WebUri? url) async {
    if (completing || url == null) return;
    final authenticatedPath =
        url.path.startsWith('/mis-tarjetas') ||
        url.path.startsWith('/mi-cuenta');
    final isAucorsa = url.host == 'aucorsa.es' || url.host == 'www.aucorsa.es';
    if (!isAucorsa || !authenticatedPath) return;

    await _completeAuthentication();
  }

  Future<void> _completeAuthentication() async {
    if (completing) return;
    completing = true;
    await _storeSession();
    if (!mounted) return;
    context.pop(true);
  }

  /// Watches the page for the message the site shows when a sign-in succeeds
  /// without leaving the form, which no navigation would tell us about.
  Future<void> _watchForAuthentication(
    InAppWebViewController controller,
  ) async {
    if (completing) return;

    try {
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
    } catch (_) {
      // A navigation can temporarily make the JavaScript context unavailable.
      // The redirect the sign-in form ends on still reports the sign-in.
    }
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
    // The user may have signed in without the page noticing, so the session
    // is worth keeping either way.
    if (!completing) unawaited(_storeSession());
    super.dispose();
  }

  /// Keeps the freshly signed-in session both in the jar and in our own copy.
  Future<void> _storeSession() async {
    final cookies = CookieManager.instance();
    await AucorsaApi.persistSession(cookies);
    await AucorsaSession.save(await AucorsaApi.cookieHeader(cookies));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (progress < 1) LinearProgressIndicator(value: progress),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(AucorsaApi.signInUrl),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
