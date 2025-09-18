import 'package:aucorsa/bonobus/cubits/bonobus_cubit.dart';
import 'package:aucorsa/bonobus/widgets/bonobus_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';

class AucorsaBonobusView extends StatefulWidget {
  const AucorsaBonobusView({super.key});

  @override
  State<AucorsaBonobusView> createState() => _AucorsaBonobusViewState();
}

class _AucorsaBonobusViewState extends State<AucorsaBonobusView> {
  static const saldoMessageId = 'BALANCE_AVAILABLE';
  static const saldoMessageName = 'NAME_AVAILABLE';

  static final bonobusUri = WebUri('https://aucorsa.es/');

  late InAppWebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    final bonobus = context.watch<BonobusCubit>().state.id;

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: bonobusUri),
          onWebViewCreated: (controller) => webViewController = controller,
          onConsoleMessage: (controller, consoleMessage) {
            if (consoleMessage.message.contains(saldoMessageId)) {
              return context.read<BonobusCubit>().loaded(
                balance: consoleMessage.message
                    .replaceAll(saldoMessageId, '')
                    .trim(),
              );
            }

            if (consoleMessage.message.contains(saldoMessageName)) {
              return context.read<BonobusCubit>().loaded(
                name: consoleMessage.message
                    .replaceAll(saldoMessageName, '')
                    .trim()
                    .toLowerCase()
                    .split(' ')
                    .map(toBeginningOfSentenceCase)
                    .join(' '),
              );
            }
          },
          onLoadStop: (controller, url) {
            if (bonobus == null) return;
            return _operate(controller, bonobus);
          },
        ),
        const BonobusDetailsView(),
      ],
    );
  }

  void _operate(InAppWebViewController controller, String bonobus) {
    context.read<BonobusCubit>().loading();
    controller.evaluateJavascript(
      source:
          """
(async function () {
  document.body.style.visibility = 'visible';
  document.body.style.display = 'block';
  document.hasFocus = () => true;

  const timeoutInMs = 10000;
  const pollIntervalInMs = 500;

  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // Step 1: Fill card number
  var input = document.querySelector('input[name="ncard_selected"]');
  if (!input) return;
  input.value = '$bonobus';

  // Step 2: Check checkbox
  var checkbox = document.getElementById('privacy_content');
  if (!checkbox) return;
  checkbox.click();

  // Step 3: Tap the submit button
  var submitButton = document.querySelector('button[type="submit"]');
  if (!submitButton) return;
  submitButton.click();

  //  Step 4: Poll for the text "Saldo disponible"
  const start = Date.now();
  while (Date.now() - start < timeoutInMs) {
    if (document.body && document.body.innerText.includes("Saldo disponible")) {
      const balance = document.querySelector('.card-real-balance');
      const name = document.querySelector('.card-number-content');

      console.log("$saldoMessageId", balance?.textContent);
      console.log("$saldoMessageName", name?.textContent);

      return null;
    }
    await sleep(pollIntervalInMs);
  }
  return null;
})();
""",
    );
  }
}
