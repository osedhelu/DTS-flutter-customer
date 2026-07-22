import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/cart/presentation/screens/cart_screen.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/test_providers.dart';

import '../../../helpers/fake_cart_remote.dart';

void main() {
  testWidgets('cart_screen_empty_state_test', (tester) async {
    final router = GoRouter(
      initialLocation: '/cart',
      routes: [
        GoRoute(
          path: '/cart',
          builder: (_, __) => const CartScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          cartNotifierProvider.overrideWith(
            (ref) => CartNotifier(ref.watch(addItemUseCaseProvider), FakeCartRemoteDataSource()),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carrito vacío'), findsOneWidget);
    expect(find.text('Ir a comercios'), findsOneWidget);

    await tester.tap(find.text('Ir a comercios'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('cart_screen_navigate_to_checkout_test', (tester) async {
    final router = GoRouter(
      initialLocation: '/cart',
      routes: [
        GoRoute(
          path: '/cart',
          builder: (_, __) => const CartScreen(),
        ),
        GoRoute(
          path: '/checkout',
          builder: (_, __) => const Scaffold(body: Text('checkout-page')),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          cartNotifierProvider.overrideWith(
            (ref) => CartNotifier(ref.watch(addItemUseCaseProvider), FakeCartRemoteDataSource())
              ..addProduct(
                storeId: 1,
                storeName: 'Café',
                product: const Product(
                  id: 1,
                  name: 'Latte',
                  price: 12,
                  storeId: 1,
                  productType: ProductType.physical,
                ),
              ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('Ir al checkout'), findsOneWidget);

    await tester.tap(find.text('Ir al checkout'));
    await tester.pumpAndSettle();
    expect(find.text('checkout-page'), findsOneWidget);
  });
}
