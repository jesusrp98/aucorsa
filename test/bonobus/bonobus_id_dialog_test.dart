import 'package:aucorsa/bonobus/widgets/bonobus_id_dialog.dart';
import 'package:aucorsa/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('prefills and returns an updated card number', (tester) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showBonobusIdDialog(
              context,
              initialValue: '0546174400',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '0546174400');
    expect(
      field.controller?.selection,
      const TextSelection(baseOffset: 0, extentOffset: 10),
    );

    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(result, '1234567890');
  });

  testWidgets('starts empty when no card number is given', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showBonobusIdDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('refuses a card number that is too short', (tester) async {
    var closed = false;
    String? result;

    await tester.pumpWidget(
      _app((context) async {
        result = await showBonobusIdDialog(context);
        closed = true;
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();

    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(closed, isFalse);
    expect(result, isNull);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('accepts the number once it is ten digits long', (tester) async {
    await tester.pumpWidget(_app(showBonobusIdDialog));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.pump();

    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('keeps everything that is not a digit out of the field', (
    tester,
  ) async {
    await tester.pumpWidget(_app(showBonobusIdDialog));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '12ab34-56');
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '123456');
  });
}

Widget _app(void Function(BuildContext context) onOpen) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => TextButton(
      onPressed: () => onOpen(context),
      child: const Text('open'),
    ),
  ),
);
