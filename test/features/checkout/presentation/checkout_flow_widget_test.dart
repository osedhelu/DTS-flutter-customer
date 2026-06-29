import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/cart/application/providers/cart_providers.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:dts_customer/features/checkout/domain/entities/order.dart';
import 'package:dts_customer/features/checkout/domain/usecases/create_order_usecase.dart';
import 'package:dts_customer/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockCreateOrderUseCase extends Mock implements CreateOrderUseCase {}

void main() {
  late MockCreateOrderUseCase createOrderUseCase;

  setUpAll(() {
    registerFallbackValue(
      const CreateOrderParams(
        storeId: 0,
        items: [CreateOrderItem(productId: 0, quantity: 1)],
      ),
    );
  });

  setUp(() {
    createOrderUseCase = MockCreateOrderUseCase();
  });

  testWidgets('checkout_flow_widget_test', (tester) async {
    when(() => createOrderUseCase(any())).thenAnswer(
      (_) async => const Order(
        id: 42,
        storeId: 1,
        status: 'PENDING',
        total: 15,
        orderType: 'PHYSICAL',
      ),
    );

    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (_, __) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/orders/:orderId/tracking',
          builder: (_, state) => Scaffold(
            body: Text('tracking-${state.pathParameters['orderId']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          createOrderUseCaseProvider.overrideWithValue(createOrderUseCase),
          cartNotifierProvider.overrideWith(
            (ref) => CartNotifier(ref.watch(addItemUseCaseProvider))
              ..addProduct(
                storeId: 1,
                storeName: 'Café',
                product: const Product(
                  id: 1,
                  name: 'Latte',
                  price: 15,
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

    expect(find.byKey(const Key('checkout_total')), findsOneWidget);
    expect(find.text('Total: \$15.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm_order_button')));
    await tester.pump();
    await tester.pumpAndSettle();

    verify(() => createOrderUseCase(any())).called(1);
    expect(find.text('tracking-42'), findsOneWidget);
  });
}
