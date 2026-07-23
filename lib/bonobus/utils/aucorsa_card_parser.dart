import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

class AucorsaCardParser {
  const AucorsaCardParser._();

  static List<AucorsaCardReference> parseCardReferences(String rawHtml) {
    final references = <AucorsaCardReference>[];
    final numbers = <String>{};

    for (final element in parse(rawHtml).querySelectorAll('.card-showtitle')) {
      final number = element.attributes['data-card-number']?.trim() ?? '';
      if (number.isEmpty || !numbers.add(number)) continue;

      references.add(
        AucorsaCardReference(
          number: number,
          status: element.attributes['data-card-status']?.trim() ?? 'register',
        ),
      );
    }

    return references;
  }

  static AucorsaCard parseCard(
    String rawHtml,
    AucorsaCardReference reference,
  ) {
    final document = parse(rawHtml);
    final title = _text(document, '.card-number-content');
    final balance = _text(document, '.card-real-balance');

    if (title.isEmpty || balance.isEmpty) {
      throw const FormatException('AUCORSA returned incomplete card details');
    }

    return AucorsaCard(
      number: _text(document, '.card-number-title', fallback: reference.number),
      status: reference.status,
      title: _toTitleCase(title),
      description: _text(document, '.card-number-description'),
      balance: balance,
      canRecharge: document.querySelector('.recharge-active') != null,
    );
  }

  static AucorsaCardMovements parseMovements(String rawHtml) {
    final document = parse(rawHtml);
    final cells = document.querySelectorAll('.grid-movements-movement');
    if (cells.length % 4 != 0) {
      throw const FormatException('AUCORSA returned malformed card movements');
    }

    final movements = <AucorsaCardMovement>[];
    for (var index = 0; index < cells.length; index += 4) {
      final operationCell = cells[index + 2];
      final activationElement = operationCell.querySelector('span');
      final activationLabel = activationElement?.attributes['title']?.trim();
      final color = activationElement?.attributes['style']?.toLowerCase() ?? '';
      final normalizedLabel = activationLabel?.toLowerCase() ?? '';

      AucorsaRechargeActivation? activation;
      if (activationElement != null) {
        activation =
            color.contains('green') ||
                normalizedLabel == 'activada' ||
                normalizedLabel == 'activated'
            ? AucorsaRechargeActivation.activated
            : AucorsaRechargeActivation.pending;
      }

      movements.add(
        AucorsaCardMovement(
          date: cells[index].text.trim(),
          time: cells[index + 1].text.trim(),
          operation: operationCell.text.trim().replaceFirst(
            RegExp(r'^[●•]\s*'),
            '',
          ),
          amount: cells[index + 3].text.trim(),
          activationLabel: activationLabel,
          activation: activation,
        ),
      );
    }

    return AucorsaCardMovements(
      movements: movements,
      hasPreviousPage:
          document.querySelector('.card-movements-prev-page') != null,
      hasNextPage: document.querySelector('.card-movements-next-page') != null,
    );
  }

  static String _text(
    Document document,
    String selector, {
    String fallback = '',
  }) {
    final value = document.querySelector(selector)?.text.trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  static String _toTitleCase(String value) => value
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
