import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dts_customer/features/checkout/presentation/widgets/payment_sandbox_sheet.dart';

void main() {
  testWidgets('payment_sandbox_sheet_error_test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  PaymentSandboxSheet.show(
                    context,
                    total: 20,
                    onPay: (_) async {
                      throw Exception('pay failed');
                    },
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pagar ahora'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo simular el pago'), findsOneWidget);
  });
}
