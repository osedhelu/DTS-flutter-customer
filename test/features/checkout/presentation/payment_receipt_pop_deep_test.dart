import 'dart:async';

import 'package:dts_customer/core/debug/agent_debug_log.dart';
import 'package:dts_customer/features/checkout/domain/entities/payment_receipt.dart';
import 'package:dts_customer/features/checkout/presentation/screens/payment_receipt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'H1b: popUntil isFirst over multi-push go_router stack crashes',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      observers: [AgentNavObserver(tag: 'test-deep')],
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, __) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                agentDebugLog(
                  location: 'payment_receipt_pop_deep_test.dart:push',
                  message: 'push receipt on deep stack',
                  hypothesisId: 'H1',
                  data: {
                    'canPop': GoRouter.of(context).canPop(),
                    'loc': GoRouterState.of(context).matchedLocation,
                  },
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
        GoRoute(
          path: '/stores/:id',
          builder: (_, __) => const Scaffold(body: Text('store')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Build imperative stack: home -> store -> checkout (like real shopping).
    router.push('/stores/1');
    await tester.pumpAndSettle();
    router.push('/checkout');
    await tester.pumpAndSettle();

    agentDebugLog(
      location: 'payment_receipt_pop_deep_test.dart:stack',
      message: 'deep stack ready',
      hypothesisId: 'H1',
      data: {
        'canPop': router.canPop(),
        'uri': router.routerDelegate.currentConfiguration.uri.toString(),
      },
    );

    await tester.tap(find.text('open-receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Ver pedido'), findsOneWidget);

    Object? caught;
    StackTrace? stack;
    await runZonedGuarded(() async {
      await tester.tap(find.text('Ver pedido'));
      await tester.pumpAndSettle();
    }, (e, st) {
      caught = e;
      stack = st;
      agentDebugLog(
        location: 'payment_receipt_pop_deep_test.dart:catch',
        message: 'caught during popUntil deep',
        hypothesisId: 'H1',
        data: {
          'error': e.toString(),
          'stackHead': st.toString().split('\n').take(10).join(' | '),
        },
      );
    });

    // Also try system-style maybePop after a fresh deep push if needed.
    agentDebugLog(
      location: 'payment_receipt_pop_deep_test.dart:result',
      message: 'deep test finished',
      hypothesisId: 'H1',
      data: {
        'caught': caught?.toString(),
        'hasHandlePopPage':
            stack?.toString().contains('_handlePopPage') ?? false,
        'hasNullCheck':
            caught?.toString().contains('Null check operator') ?? false,
      },
    );

    // Surface for CI visibility without failing the harness if we only observe.
    expect(true, isTrue);
  });

  testWidgets('H3: push /cart then maybePop', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      observers: [AgentNavObserver(tag: 'test-cart')],
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return Scaffold(
              body: navigationShell,
              bottomNavigationBar: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: navigationShell.goBranch,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home), label: 'H'),
                  NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'C'),
                ],
              ),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const Text('home'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  builder: (_, __) => const Text('cart'),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/stores/:id',
          builder: (context, __) => Scaffold(
            appBar: AppBar(),
            body: ElevatedButton(
              onPressed: () {
                agentDebugLog(
                  location: 'cart_push_pop_test.dart:pushCart',
                  message: 'context.push /cart from store',
                  hypothesisId: 'H3',
                );
                context.push('/cart');
              },
              child: const Text('to-cart'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.push('/stores/9');
    await tester.pumpAndSettle();
    await tester.tap(find.text('to-cart'));
    await tester.pumpAndSettle();

    Object? caught;
    await runZonedGuarded(() async {
      // Simulate AppBar/system back.
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      await nav.maybePop();
      await tester.pumpAndSettle();
    }, (e, st) {
      caught = e;
      agentDebugLog(
        location: 'cart_push_pop_test.dart:catch',
        message: 'caught maybePop after push /cart',
        hypothesisId: 'H3',
        data: {
          'error': e.toString(),
          'stackHead': st.toString().split('\n').take(10).join(' | '),
        },
      );
    });

    agentDebugLog(
      location: 'cart_push_pop_test.dart:result',
      message: 'H3 finished',
      hypothesisId: 'H3',
      data: {'caught': caught?.toString()},
    );
  });
}
