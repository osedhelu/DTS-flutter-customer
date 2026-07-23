import 'package:dts_customer/core/debug/agent_debug_log.dart';
import 'package:dts_customer/features/checkout/domain/entities/payment_receipt.dart';
import 'package:dts_customer/features/checkout/presentation/widgets/payment_sandbox_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

PaymentReceipt _receipt() => PaymentReceipt(
      orderId: 42,
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
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'H1: inline receipt Ver pedido + go tracking (no Future completed)',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/checkout',
      observers: [AgentNavObserver(tag: 'inline-receipt')],
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (context, __) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final paid = await PaymentSandboxSheet.show(
                  context,
                  total: 10,
                  onPay: (_) async => _receipt(),
                );
                if (context.mounted && paid == true) {
                  context.go('/tracking/42');
                }
              },
              child: const Text('open-sheet'),
            ),
          ),
        ),
        GoRoute(
          path: '/tracking/:id',
          builder: (_, __) => const Scaffold(body: Text('tracking')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        builder: (context, child) => Stack(
          children: [child ?? const SizedBox.shrink()],
        ),
        routerConfig: router,
      ),
    );
    await tester.pump();

    Object? flutterErr;
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      flutterErr ??= details.exception;
      agentDebugLog(
        location: 'ver_pedido_inline_test:FlutterError',
        message: 'error during inline receipt flow',
        hypothesisId: 'H1',
        runId: 'post-fix',
        data: {'error': details.exceptionAsString()},
      );
    };

    await tester.tap(find.text('open-sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pagar ahora'));
    await tester.pumpAndSettle();

    expect(find.text('Pago confirmado'), findsOneWidget);
    expect(find.text('Ver pedido'), findsOneWidget);

    await tester.ensureVisible(find.text('Ver pedido'));
    await tester.tap(find.text('Ver pedido'));
    await tester.pumpAndSettle();

    FlutterError.onError = old;
    final take = tester.takeException();

    agentDebugLog(
      location: 'ver_pedido_inline_test:result',
      message: 'inline flow finished',
      hypothesisId: 'H1',
      runId: 'post-fix',
      data: {
        'flutterErr': flutterErr?.toString(),
        'takeException': take?.toString(),
        'hasTracking': find.text('tracking').evaluate().isNotEmpty,
      },
    );

    expect(flutterErr, isNull);
    expect(take, isNull);
    expect(find.text('tracking'), findsOneWidget);
  });
}
