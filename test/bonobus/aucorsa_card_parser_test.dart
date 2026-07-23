import 'package:aucorsa/bonobus/models/aucorsa_card.dart';
import 'package:aucorsa/bonobus/utils/aucorsa_card_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AucorsaCardParser', () {
    test('extracts every unique linked card reference', () {
      const html = '''
        <div class="card-showtitle" data-card-number="111" data-card-status="register"></div>
        <div class="card-showtitle" data-card-number="222" data-card-status="blocked"></div>
        <div class="card-showtitle" data-card-number="111" data-card-status="register"></div>
      ''';

      expect(
        AucorsaCardParser.parseCardReferences(html),
        const [
          AucorsaCardReference(number: '111', status: 'register'),
          AucorsaCardReference(number: '222', status: 'blocked'),
        ],
      );
    });

    test('extracts all card details returned by showtitle', () {
      const html = '''
        <div class="card-number-title">123456789</div>
        <div class="card-number-content">TARJETA ESTUDIANTE</div>
        <div class="card-number-description">MONEDERO</div>
        <div class="card-real-balance">8.87 €</div>
        <button class="recharge-active">Recargar</button>
      ''';

      final card = AucorsaCardParser.parseCard(
        html,
        const AucorsaCardReference(number: '123456789', status: 'register'),
      );

      expect(card.number, '123456789');
      expect(card.title, 'Tarjeta Estudiante');
      expect(card.description, 'MONEDERO');
      expect(card.balance, '8.87 €');
      expect(card.canRecharge, isTrue);
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

      expect(result.hasPreviousPage, isTrue);
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
      expect(result.movements.last.activationLabel, 'Activada');
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
      expect(movement.activationLabel, 'Pendiente');
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
