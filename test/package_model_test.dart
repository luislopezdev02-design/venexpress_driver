import 'package:flutter_test/flutter_test.dart';
import 'package:venexpress_driver/models/package_model.dart';

Map<String, dynamic> _json(Map<String, dynamic> overrides) => {
      'id': 1,
      'tracking_number': 'VEN-1',
      'current_status': 'EN_RUTA',
      'status_label': 'En ruta de entrega',
      'sender': {'name': 'Juan', 'phone': '0414'},
      'recipient': {'name': 'María', 'phone': '0424'},
      'requires_delivery': true,
      'package_type': 'paquete',
      'is_fragile': false,
      'is_cod': true,
      'cod_amount_usd': 25,
      'security_warning': false,
      ...overrides,
    };

void main() {
  test('lee el PIN de entrega y el cobro pendiente de un paquete en ruta', () {
    final package = PackageModel.fromJson(_json({
      'has_delivery_pin': true,
      'delivery_pin_attempts_left': 4,
    }));

    expect(package.isOutForDelivery, isTrue);
    expect(package.hasDeliveryPin, isTrue);
    expect(package.deliveryPinAttemptsLeft, 4);
    expect(package.codPendingAtDelivery, isTrue);
    expect(package.isDeliveryFailed, isFalse);
  });

  test('una respuesta sin los campos nuevos usa valores seguros', () {
    final package = PackageModel.fromJson(_json({'is_cod': false}));

    expect(package.hasDeliveryPin, isFalse);
    expect(package.deliveryAttempts, 0);
    expect(package.receivedByThirdParty, isFalse);
    expect(package.codPendingAtDelivery, isFalse);
  });

  test('lee una entrega fallida', () {
    final package = PackageModel.fromJson(_json({
      'current_status': 'ENTREGA_FALLIDA',
      'delivery_attempts': 2,
      'failed_delivery_reason': 'CLIENTE_AUSENTE',
      'failed_delivery_reason_label': 'Destinatario ausente',
      'cod_collected_at': '2026-10-06T10:00:00Z',
    }));

    expect(package.isDeliveryFailed, isTrue);
    expect(package.isOutForDelivery, isFalse);
    expect(package.deliveryAttempts, 2);
    expect(package.failedDeliveryReasonLabel, 'Destinatario ausente');
    expect(package.codPendingAtDelivery, isFalse);
  });
}
