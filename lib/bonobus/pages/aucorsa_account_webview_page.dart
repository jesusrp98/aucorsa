import 'dart:async';

import 'package:aucorsa/bonobus/utils/aucorsa_api.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class AucorsaAccountWebViewPage extends StatefulWidget {
  /// Page the web view opens on.
  final String initialUrl;

  /// Whether reaching the account area pops the page with `true`.
  final bool detectAuthentication;

  const AucorsaAccountWebViewPage({super.key})
    : initialUrl = AucorsaApi.signInUrl,
      detectAuthentication = true;

  /// Opens the AUCORSA card list so the user can manage their linked cards.
  ///
  /// The page stays open until the user closes it, since browsing the account
  /// is the goal here instead of signing in.
  const AucorsaAccountWebViewPage.cards({super.key})
    : initialUrl = AucorsaApi.cardsUrl,
      detectAuthentication = false;

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
    if (!widget.detectAuthentication || completing || url == null) return;
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
    authenticationPoller?.cancel();
    await _storeSession();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _startAuthenticationPolling(InAppWebViewController controller) {
    if (!widget.detectAuthentication || completing) return;
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
    if (!widget.detectAuthentication || completing) return;

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
    // The user may have signed in without the page noticing, or come here to
    // manage their cards. Either way the session is worth keeping.
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
