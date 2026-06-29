import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/cart/application/providers/cart_providers.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:dts_customer/features/checkout/domain/entities/order.dart';
import 'package:dts_customer/features/checkout/domain/usecases/create_service_order_usecase.dart';
import 'package:dts_customer/features/checkout/presentation/screens/service_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockCreateServiceOrderUseCase extends Mock
    implements CreateServiceOrderUseCase {}

void main() {
  late MockCreateServiceOrderUseCase createServiceOrderUseCase;

  setUpAll(() {
    registerFallbackValue(
      const CreateServiceOrderParams(
        storeId: 0,
        items: [CreateOrderItem(productId: 0, quantity: 1)],
        serviceAddress: 'addr',
      ),
    );
  });

  setUp(() {
    createServiceOrderUseCase = MockCreateServiceOrderUseCase();
  });

  testWidgets('service_checkout_flow_test', (tester) async {
    when(() => createServiceOrderUseCase(any())).thenAnswer(
      (_) async => const Order(
        id: 77,
        storeId: 2,
        status: 'PENDING',
        total: 50,
        orderType: 'SERVICE',
        serviceAddress: 'Calle 100 #10-20',
      ),
    );

    final router = GoRouter(
      initialLocation: '/checkout/service',
      routes: [
        GoRoute(
          path: '/checkout/service',
          builder: (_, __) => const ServiceCheckoutScreen(),
        ),
        GoRoute(
          path: '/orders/:orderId/service-tracking',
          builder: (_, state) => Scaffold(
            body: Text('service-tracking-${state.pathParameters['orderId']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          createServiceOrderUseCaseProvider
              .overrideWithValue(createServiceOrderUseCase),
          cartNotifierProvider.overrideWith(
            (ref) => CartNotifier(ref.watch(addItemUseCaseProvider))
              ..addProduct(
                storeId: 2,
                storeName: 'Spa',
                product: const Product(
                  id: 9,
                  name: 'Masaje',
                  price: 50,
                  storeId: 2,
                  productType: ProductType.service,
                ),
              ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('service_address_field')),
      'Calle 100 #10-20',
    );
    await tester.enterText(
      find.byKey(const Key('service_notes_field')),
      'Timbre 3',
    );
    await tester.tap(find.byKey(const Key('confirm_service_order_button')));
    await tester.pump();
    await tester.pumpAndSettle();

    verify(() => createServiceOrderUseCase(any())).called(1);
    expect(find.text('service-tracking-77'), findsOneWidget);
  });
}
