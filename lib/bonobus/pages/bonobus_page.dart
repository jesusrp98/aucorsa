import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BonobusPage extends StatefulWidget {
  static const path = '/bonobus';

  const BonobusPage({super.key});

  @override
  State<BonobusPage> createState() => _BonobusPageState();
}

class _BonobusPageState extends State<BonobusPage> {
  late InAppWebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cloudflare Challenge")),
      body: InAppWebView(
        initialFile: 'assets/turnstile.html',
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
          controller.addJavaScriptHandler(
            handlerName: 'turnstileCallback',
            callback: (args) async {
              final token = args.first;
              print("✅ Turnstile token: $token");
              // You can now call your backend API with this token                Or use it in another WebView/page
              Navigator.pop(context, token);
            },
          );
        },
      ),
    );
    // return Scaffold(
    //   appBar: AppBar(title: const Text("Invisible WebView")),
    //   body: Stack(
    //     children: [
    //       InAppWebView(
    //         initialUrlRequest: URLRequest(url: WebUri("https:aucorsa.es/")),
    //         onWebViewCreated: (controller) {
    //           webViewController = controller;
    //         },
    //         onConsoleMessage: (controller, consoleMessage) {
    //           print("Console message: ${consoleMessage.message}");
    //           if (consoleMessage.message.contains(saldoMessage)) {
    //             ScaffoldMessenger.of(context).showSnackBar(
    //               SnackBar(
    //                 content: Text(
    //                   "Saldo disponible: ${consoleMessage.message.replaceAll(saldoMessage, '')}",
    //                 ),
    //               ),
    //             );
    //           }
    //         },
    //         onLoadStop: (controller, url) async {
    //           final result = await controller.evaluateJavascript(
    //             source:
    //                 """
    //          (async function () {             document.body.style.visibility = 'visible';
    //        document.body.style.display = 'block';           document.hasFocus = () => true;
    //            const timeoutMs = 10000;               const pollInterval = 500;
    //            function sleep(ms) {
    //              return new Promise(resolve => setTimeout(resolve, ms));               }
    //             Step 1: Fill card number
    //            var input = document.querySelector('input[name="ncard_selected"]');             console.log("Paso 1");
    //            if (!input) return;               input.value = '$cardId';
    //             Step 2: Check checkbox
    //            var checkbox = document.getElementById('privacy_content');
    //            if (!checkbox) return;               checkbox.click();
    //          console.log("Paso 2");
    //             Step 3: Tap the submit button               var submitButton = document.querySelector('button[type="submit"]');
    //            if (!submitButton) return;
    //            submitButton.click();
    //          console.log("Paso 3");
    //             Step 4: Poll for the text "Saldo disponible"               const start = Date.now();
    //            while (Date.now() - start < timeoutMs) {           console.log("Paso 4.1");
    //              if (document.body && document.body.innerText.includes("Saldo disponible")) {                 const el = document.querySelector('.card-real-balance');
    //              console.log("Paso 4.2");
    //          console.log("$saldoMessage", el?.getAttribute('data-value')  el?.textContent  null);             return null;
    //              }
    //              await sleep(pollInterval);
    //            }
    //            return null;             })();
    //          """,
    //           );
    //         },
    //       ),
    //       Positioned.fill(child: Container(color: Colors.red)),
    //     ],
    //   ),
    // );
  }
}
