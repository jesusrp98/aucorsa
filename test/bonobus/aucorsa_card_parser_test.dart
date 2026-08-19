import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_card_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AucorsaCardParser', () {
    test('extracts the card title and balance', () {
      const html = '''
        <div class="card-number-title">123456789</div>
        <div class="card-number-content">TARJETA ESTUDIANTE</div>
        <div class="card-number-description">MONEDERO</div>
        <div class="card-real-balance">8.87 €</div>
        <button class="recharge-active">Recargar</button>
      ''';

      final card = AucorsaCardParser.parseCard(html);

      expect(card.title, 'Tarjeta Estudiante');
      expect(card.balance, '8.87 €');
    });

    test('extracts card details returned by the public recharge form', () {
      const html = '''
        <input type="hidden" name="card_number_precharge" value="1234567890">
        <div class="card-number-content">TARJETA ORDINARIA</div>
        <div class="card-number-title">1234567890</div>
        <div class="card-real-balance">12.34 &euro;</div>
      ''';

      final card = AucorsaCardParser.parseCard(html);

      expect(card.title, 'Tarjeta Ordinaria');
      expect(card.balance, '12.34 €');
    });

    test('rejects a card fragment with no balance in it', () {
      const html = '<div class="card-number-content">TARJETA</div>';

      expect(
        () => AucorsaCardParser.parseCard(html),
        throwsFormatException,
      );
    });

    test('rejects a card fragment with no title in it', () {
      const html = '<div class="card-real-balance">8.87 €</div>';

      expect(
        () => AucorsaCardParser.parseCard(html),
        throwsFormatException,
      );
    });

    test('rejects a card fragment the site left blank', () {
      const html = '''
        <div class="card-number-content"></div>
        <div class="card-real-balance"></div>
      ''';

      expect(
        () => AucorsaCardParser.parseCard(html),
        throwsFormatException,
      );
    });

    test('titles a name the site shouts across several words', () {
      const html = '''
        <div class="card-number-content">TARJETA  JOVEN   ANUAL</div>
        <div class="card-real-balance">8.87 €</div>
      ''';

      expect(AucorsaCardParser.parseCard(html).title, 'Tarjeta Joven Anual');
    });

    test('extracts movement details, activation state, and pagination', () {
      const html = '''
        <div class="grid-movements-movement">01/07/2026</div>
        <div class="grid-movements-movement">08:13</div>
        <div class="grid-movements-movement">Validación bus</div>
        <div class="grid-movements-movement">-0,58 €</div>
        <div class="grid-movements-movement">30/06/2026</div>
        <div class="grid-movements-movement">19:42</div>
        <div class="grid-movements-movement"><span title="Activada" style="color: green">●</span> Recarga online</div>
        <div class="grid-movements-movement">10,00 €</div>
        <button class="card-movements-prev-page"></button>
        <button class="card-movements-next-page"></button>
      ''';

      final result = AucorsaCardParser.parseMovements(html);

      expect(result.hasNextPage, isTrue);
      expect(result.movements, hasLength(2));
      expect(
        result.movements.first,
        const AucorsaCardMovement(
          date: '01/07/2026',
          time: '08:13',
          operation: 'Validación bus',
          amount: '-0,58 €',
        ),
      );
      expect(result.movements.last.operation, 'Recarga online');
      expect(
        result.movements.last.activation,
        AucorsaRechargeActivation.activated,
      );
    });

    test('treats a non-green recharge marker as pending activation', () {
      const html = '''
        <div class="grid-movements-movement">30/06/2026</div>
        <div class="grid-movements-movement">19:42</div>
        <div class="grid-movements-movement"><span title="Pendiente" style="color: red">●</span> Recarga online</div>
        <div class="grid-movements-movement">10,00 €</div>
      ''';

      final movement = AucorsaCardParser.parseMovements(html).movements.single;

      expect(movement.activation, AucorsaRechargeActivation.pending);
    });

    test('reads the activation state the site words in English', () {
      const html = '''
        <div class="grid-movements-movement">30/06/2026</div>
        <div class="grid-movements-movement">19:42</div>
        <div class="grid-movements-movement"><span title="Activated">●</span> Recarga online</div>
        <div class="grid-movements-movement">10,00 €</div>
      ''';

      final movement = AucorsaCardParser.parseMovements(html).movements.single;

      expect(movement.activation, AucorsaRechargeActivation.activated);
    });

    test('leaves a movement that carries no marker unflagged', () {
      const html = '''
        <div class="grid-movements-movement">01/07/2026</div>
        <div class="grid-movements-movement">08:13</div>
        <div class="grid-movements-movement">Validación bus</div>
        <div class="grid-movements-movement">-0,58 €</div>
      ''';

      final movement = AucorsaCardParser.parseMovements(html).movements.single;

      expect(movement.activation, isNull);
    });

    test('strips the bullet the marker leaves in the operation', () {
      const html = '''
        <div class="grid-movements-movement">30/06/2026</div>
        <div class="grid-movements-movement">19:42</div>
        <div class="grid-movements-movement"><span title="Pendiente">•</span> Recarga online</div>
        <div class="grid-movements-movement">10,00 €</div>
      ''';

      final movement = AucorsaCardParser.parseMovements(html).movements.single;

      expect(movement.operation, 'Recarga online');
    });

    test('reads an empty history as a page without movements', () {
      final result = AucorsaCardParser.parseMovements('<div></div>');

      expect(result.movements, isEmpty);
      expect(result.hasNextPage, isFalse);
    });

    test('reports the last page as having nothing after it', () {
      const html = '''
        <div class="grid-movements-movement">01/07/2026</div>
        <div class="grid-movements-movement">08:13</div>
        <div class="grid-movements-movement">Validación bus</div>
        <div class="grid-movements-movement">-0,58 €</div>
        <a class="card-movements-prev-page"></a>
      ''';

      expect(AucorsaCardParser.parseMovements(html).hasNextPage, isFalse);
    });

    test('rejects malformed movement grids', () {
      const html = '''
        <div class="grid-movements-movement">01/07/2026</div>
        <div class="grid-movements-movement">08:13</div>
      ''';

      expect(
        () => AucorsaCardParser.parseMovements(html),
        throwsFormatException,
      );
    });
  });
}
