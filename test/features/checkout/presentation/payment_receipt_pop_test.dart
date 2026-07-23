import 'dart:async';

import 'package:dts_customer/core/debug/agent_debug_log.dart';
import 'package:dts_customer/features/checkout/domain/entities/payment_receipt.dart';
import 'package:dts_customer/features/checkout/presentation/screens/payment_receipt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Reproduce crash: PaymentReceipt popUntil(isFirst) over go_router pages.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('H1: popUntil isFirst after imperative receipt push',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      observers: [AgentNavObserver(tag: 'test')],
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  agentDebugLog(
                    location: 'payment_receipt_pop_test.dart:push',
                    message: 'test pushing receipt',
                    hypothesisId: 'H1',
                  );
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => PaymentReceiptScreen(
                        receipt: PaymentReceipt(
                          orderId: 1,
                          paymentStatus: 'paid',
                          paymentMethodLabel: 'Sandbox',
                          paymentReference: 'ref',
                          paidAt: DateTime.utc(2026, 1, 1),
                          subtotal: 10,
                          discountAmount: 0,
                          totalPaid: 10,
                          platformCommissionRate: 0.1,
                          platformCommission: 1,
                          merchantNet: 9,
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open-receipt'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/tracking/:id',
          builder: (_, __) => const Scaffold(body: Text('tracking')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open-receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Ver pedido'), findsOneWidget);

    Object? caught;
    await runZonedGuarded(() async {
      await tester.tap(find.text('Ver pedido'));
      await tester.pumpAndSettle();
    }, (e, st) {
      caught = e;
      agentDebugLog(
        location: 'payment_receipt_pop_test.dart:catch',
        message: 'caught during popUntil',
        hypothesisId: 'H1',
        data: {
          'error': e.toString(),
          'stack': st.toString().split('\n').take(8).join(' | '),
        },
      );
    });

    agentDebugLog(
      location: 'payment_receipt_pop_test.dart:result',
      message: 'test finished',
      hypothesisId: 'H1',
      data: {
        'caught': caught?.toString(),
        'hasVerPedido': find.text('Ver pedido').evaluate().isNotEmpty,
        'hasHome': find.text('open-receipt').evaluate().isNotEmpty,
      },
    );
  });
}
