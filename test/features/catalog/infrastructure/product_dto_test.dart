import 'package:dts_customer/features/catalog/infrastructure/models/product_dto.dart';
import 'package:dts_customer/features/catalog/presentation/widgets/dynamic_fields_form.dart';
import 'package:dts_customer/features/checkout/domain/entities/payment_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('productDetailFromPublicJson', () {
    test('maps flat public detail payload with field_config', () {
      final detail = productDetailFromPublicJson({
        'id': 12,
        'name': 'Lavado express',
        'price': '45000.00',
        'store_id': 3,
        'product_type': 'service',
        'category_id': 1,
        'subcategory_id': null,
        'description': 'A domicilio',
        'duration_minutes': 60,
        'stock': 0,
        'dynamic_values': {},
        'images': [
          {'url': 'https://cdn.example.com/lavado.jpg'},
        ],
        'field_config': {'kg': 'texto_libre'},
      });

      expect(detail.product.id, 12);
      expect(detail.product.name, 'Lavado express');
      expect(detail.product.primaryImageUrl, 'https://cdn.example.com/lavado.jpg');
      expect(detail.fieldConfig, {'kg': 'texto_libre'});
      expect(detail.images, ['https://cdn.example.com/lavado.jpg']);
    });
  });

  group('formatDynamicValuesNotes', () {
    test('formats structured service notes', () {
      final notes = formatDynamicValuesNotes({'kg': '5', 'prenda': 'Mixto'});
      expect(notes, contains('kg: 5'));
      expect(notes, contains('prenda: Mixto'));
    });
  });

  group('PaymentReceipt.fromJson', () {
    test('parses sandbox receipt payload', () {
      final receipt = PaymentReceipt.fromJson({
        'order_id': 99,
        'payment_status': 'paid',
        'payment_reference': 'sandbox:99:4242:20260721120000',
        'paid_at': '2026-07-21T12:00:00Z',
        'subtotal': '50000.00',
        'discount_amount': '5000.00',
        'total_paid': '45000.00',
        'platform_commission_rate': '0.1500',
        'platform_commission': '6750.00',
        'merchant_net': '38250.00',
        'payment_method_label': 'Sandbox DTS',
      });

      expect(receipt.orderId, 99);
      expect(receipt.paymentStatus, 'paid');
      expect(receipt.totalPaid, 45000);
      expect(receipt.merchantNet, 38250);
      expect(receipt.paymentMethodLabel, 'Sandbox DTS');
    });
  });
}
