import 'package:dio/dio.dart';
import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/core/network/api_client.dart';
import 'package:dts_customer/core/network/token_storage.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:dts_customer/features/checkout/domain/entities/order.dart';
import 'package:dts_customer/features/checkout/domain/usecases/create_order_usecase.dart';
import 'package:dts_customer/features/checkout/infrastructure/datasources/orders_remote_datasource.dart';
import 'package:dts_customer/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:dts_customer/features/profile/domain/entities/customer_profile.dart';
import 'package:dts_customer/features/profile/infrastructure/datasources/customer_profile_remote_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

import '../../../helpers/fake_cart_remote.dart';

class MockCreateOrderUseCase extends Mock implements CreateOrderUseCase {}

class MockCustomerProfileRemoteDataSource extends Mock
    implements CustomerProfileRemoteDataSource {}

class MockOrdersRemoteDataSource extends Mock
    implements OrdersRemoteDataSource {}

ApiClient _apiClient({
  required Map<String, dynamic> Function(RequestOptions) onRequest,
}) {
  final storage = InMemoryTokenStorage();
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          final data = onRequest(options);
          if (data['__error'] == true) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 400,
                  data: data['body'] ?? {'detail': 'error'},
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: data['body'],
            ),
          );
        } catch (e) {
          handler.reject(
            DioException(requestOptions: options, error: e),
          );
        }
      },
    ),
  );
  return ApiClient(tokenStorage: storage, dio: dio);
}

void main() {
  late MockCreateOrderUseCase createOrderUseCase;
  late MockCustomerProfileRemoteDataSource profileDs;
  late MockOrdersRemoteDataSource ordersDs;

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
    ordersDs = MockOrdersRemoteDataSource();
    when(() => profileDs.getProfile()).thenAnswer(
      (_) async => const CustomerProfile(
        fullName: 'Ana',
        email: 'ana@test.com',
        phone: '300',
        photoUrl: '',
        defaultAddress: 'Calle 1',
      ),
    );
    when(() => profileDs.listAddresses()).thenAnswer((_) async => []);
  });

  Future<void> pumpCheckout(
    WidgetTester tester, {
    required ApiClient apiClient,
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (_, __) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/tracking/:orderId',
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
          apiClientProvider.overrideWithValue(apiClient),
          ordersRemoteDataSourceProvider.overrideWithValue(ordersDs),
          cartNotifierProvider.overrideWith(
            (ref) => CartNotifier(ref.watch(addItemUseCaseProvider), FakeCartRemoteDataSource())
              ..addProduct(
                storeId: 1,
                storeName: 'Café',
                product: const Product(
                  id: 10,
                  name: 'Latte',
                  price: 15,
                  storeId: 1,
                  productType: ProductType.physical,
                ),
              ),
          ),
          ...extra,
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('checkout_coupon_validate_success_test', (tester) async {
    final apiClient = _apiClient(
      onRequest: (options) {
        if (options.path.contains('payment-methods')) {
          return {'body': <dynamic>[]};
        }
        if (options.path.contains('coupons/validate')) {
          return {
            'body': {'discount_amount': '5.00', 'valid': true},
          };
        }
        return {'body': <String, dynamic>{}};
      },
    );

    await pumpCheckout(tester, apiClient: apiClient);

    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'SAVE5');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Descuento'), findsWidgets);
    expect(find.byKey(const Key('checkout_total')), findsOneWidget);
    expect(find.text('\$10.00'), findsWidgets);
  });

  testWidgets('checkout_coupon_invalid_test', (tester) async {
    final apiClient = _apiClient(
      onRequest: (options) {
        if (options.path.contains('payment-methods')) {
          return {'body': <dynamic>[]};
        }
        if (options.path.contains('coupons/validate')) {
          return {
            '__error': true,
            'body': {'detail': 'invalid'},
          };
        }
        return {'body': <String, dynamic>{}};
      },
    );

    await pumpCheckout(tester, apiClient: apiClient);

    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'BAD');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Cupón no válido'), findsOneWidget);
  });

  testWidgets('checkout_sandbox_flow_test', (tester) async {
    when(() => createOrderUseCase(any())).thenAnswer(
      (_) async => const Order(
        id: 55,
        storeId: 1,
        status: 'PENDING',
        total: 15,
        orderType: 'PHYSICAL',
      ),
    );
    when(
      () => ordersDs.sandboxPay(
        orderId: any(named: 'orderId'),
        cardLast4: any(named: 'cardLast4'),
      ),
    ).thenAnswer(
      (_) async => {
        'order_id': 55,
        'payment_status': 'paid',
        'payment_reference': 'SBX-1',
        'paid_at': '2026-07-21T12:00:00Z',
        'subtotal': '15',
        'discount_amount': '0',
        'total_paid': '15',
        'platform_commission_rate': '0.1',
        'platform_commission': '1.5',
        'merchant_net': '13.5',
        'payment_method_label': 'Sandbox',
      },
    );

    final apiClient = _apiClient(
      onRequest: (options) {
        if (options.path.contains('payment-methods')) {
          return {
            'body': [
              {
                'id': 9,
                'name': 'Sandbox DTS (simulado)',
                'method_type': 'sandbox',
                'instructions': 'Pago de prueba',
              },
            ],
          };
        }
        return {'body': <String, dynamic>{}};
      },
    );

    await pumpCheckout(tester, apiClient: apiClient);

    expect(find.text('Sandbox DTS (simulado)'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Calle 1');
    await tester.tap(find.byKey(const Key('confirm_order_button')));
    await tester.pumpAndSettle();

    expect(find.text('Sandbox DTS'), findsOneWidget);
    await tester.tap(find.text('Pagar ahora'));
    await tester.pumpAndSettle();

    verify(
      () => ordersDs.sandboxPay(orderId: 55, cardLast4: any(named: 'cardLast4')),
    ).called(1);
    expect(find.text('Pago confirmado'), findsOneWidget);
    expect(find.textContaining('Pedido #55'), findsOneWidget);
  });
}
