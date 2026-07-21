import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/cart/application/providers/cart_providers.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:dts_customer/features/checkout/domain/entities/order.dart';
import 'package:dts_customer/features/checkout/domain/usecases/create_order_usecase.dart';
import 'package:dts_customer/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:dts_customer/features/profile/domain/entities/customer_profile.dart';
import 'package:dts_customer/features/profile/infrastructure/datasources/customer_profile_remote_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockCreateOrderUseCase extends Mock implements CreateOrderUseCase {}

class MockCustomerProfileRemoteDataSource extends Mock
    implements CustomerProfileRemoteDataSource {}

void main() {
  late MockCreateOrderUseCase createOrderUseCase;
  late MockCustomerProfileRemoteDataSource profileDs;

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
    profileDs = MockCustomerProfileRemoteDataSource();
    when(() => profileDs.getProfile()).thenAnswer(
      (_) async => const CustomerProfile(
        fullName: 'Ana',
        email: 'ana@test.com',
        phone: '300',
        photoUrl: '',
        defaultAddress: 'Calle 1 #2-3',
      ),
    );
    when(() => profileDs.listAddresses()).thenAnswer((_) async => []);
  });

  testWidgets('checkout_flow_widget_test', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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
          customerProfileRemoteDataSourceProvider.overrideWithValue(profileDs),
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
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('checkout_total')), findsOneWidget);
    expect(find.text('Total: \$15.00'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Calle 1 #2-3');
    await tester.tap(find.text('Confirmar pedido').last);
    await tester.pump();
    await tester.pumpAndSettle();

    verify(() => createOrderUseCase(any())).called(1);
    expect(find.text('tracking-42'), findsOneWidget);
  });
}
