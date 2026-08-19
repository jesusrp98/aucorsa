import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

class AucorsaCardParser {
  const AucorsaCardParser._();

  static AucorsaCard parseCard(String rawHtml) {
    final document = parse(rawHtml);
    final title = _text(document, '.card-number-content');
    final balance = _text(document, '.card-real-balance');

    if (title.isEmpty || balance.isEmpty) {
      throw const FormatException('AUCORSA returned incomplete card details');
    }

    return AucorsaCard(title: _toTitleCase(title), balance: balance);
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
      final color = activationElement?.attributes['style']?.toLowerCase() ?? '';
      final label =
          activationElement?.attributes['title']?.trim().toLowerCase() ?? '';

      AucorsaRechargeActivation? activation;
      if (activationElement != null) {
        activation =
            color.contains('green') ||
                label == 'activada' ||
                label == 'activated'
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
          activation: activation,
        ),
      );
    }

    return AucorsaCardMovements(
      movements: movements,
      hasNextPage: document.querySelector('.card-movements-next-page') != null,
    );
  }

  static String _text(Document document, String selector) =>
      document.querySelector(selector)?.text.trim() ?? '';

  static String _toTitleCase(String value) => value
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
