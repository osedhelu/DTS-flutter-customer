import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/core/network/api_client.dart';
import 'package:dts_customer/core/network/token_storage.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:dts_customer/features/checkout/domain/entities/order.dart';
import 'package:dts_customer/features/checkout/domain/usecases/create_order_usecase.dart';
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
import 'package:dio/dio.dart';

class MockCreateOrderUseCase extends Mock implements CreateOrderUseCase {}

class MockCustomerProfileRemoteDataSource extends Mock
    implements CustomerProfileRemoteDataSource {}

ApiClient _apiClientWithHandlers({
  List<Map<String, dynamic>> paymentMethods = const [],
  Map<String, dynamic>? couponResponse,
  bool couponFails = false,
}) {
  final storage = InMemoryTokenStorage();
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;
        if (path.contains('payment-methods')) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: paymentMethods,
            ),
          );
          return;
        }
        if (path.contains('coupons/validate')) {
          if (couponFails) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 400,
                  data: {'detail': 'invalid'},
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: couponResponse ?? {'discount_amount': '5.00'},
            ),
          );
          return;
        }
        handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: {}),
        );
      },
    ),
  );
  return ApiClient(tokenStorage: storage, dio: dio);
}

Widget _checkoutApp({
  required List<Override> overrides,
}) {
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
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('home')),
      ),
    ],
  );

  return buildTestApp(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

List<Override> _baseOverrides({
  required MockCreateOrderUseCase createOrderUseCase,
  required MockCustomerProfileRemoteDataSource profileDs,
  required ApiClient apiClient,
  String defaultAddress = 'Calle 1 #2-3',
}) {
  when(() => profileDs.getProfile()).thenAnswer(
    (_) async => CustomerProfile(
      fullName: 'Ana',
      email: 'ana@test.com',
      phone: '300',
      photoUrl: '',
      defaultAddress: defaultAddress,
    ),
  );
  when(() => profileDs.listAddresses()).thenAnswer((_) async => []);

  return [
    createOrderUseCaseProvider.overrideWithValue(createOrderUseCase),
    customerProfileRemoteDataSourceProvider.overrideWithValue(profileDs),
    apiClientProvider.overrideWithValue(apiClient),
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
  ];
}

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
  });

  Future<void> pumpCheckout(
    WidgetTester tester, {
    required ApiClient apiClient,
  }) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _checkoutApp(
        overrides: _baseOverrides(
          createOrderUseCase: createOrderUseCase,
          profileDs: profileDs,
          apiClient: apiClient,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('checkout_requires_address_test', (tester) async {
    final apiClient = _apiClientWithHandlers();
    await pumpCheckout(tester, apiClient: apiClient);

    // Clear auto-filled default address.
    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.byKey(const Key('confirm_order_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('checkout_error')), findsOneWidget);
    expect(find.text('Ingresa una dirección de entrega'), findsOneWidget);
    verifyNever(() => createOrderUseCase(any()));
  });

  testWidgets('checkout_confirm_sends_payload_test', (tester) async {
    CreateOrderParams? captured;
    when(() => createOrderUseCase(any())).thenAnswer((invocation) async {
      captured = invocation.positionalArguments.first as CreateOrderParams;
      return const Order(
        id: 42,
        storeId: 1,
        status: 'PENDING',
        total: 15,
        orderType: 'PHYSICAL',
      );
    });

    final apiClient = _apiClientWithHandlers(
      paymentMethods: [
        {
          'id': 7,
          'name': 'Sandbox DTS (simulado)',
          'method_type': 'sandbox',
          'instructions': 'Pago de prueba',
        },
      ],
    );
    await pumpCheckout(tester, apiClient: apiClient);

    expect(find.text('Sandbox DTS (simulado)'), findsOneWidget);

    final addressField = find.byType(TextField).first;
    final notesField = find.widgetWithText(TextField, 'Notas (opcional)');
    await tester.enterText(addressField, 'Calle 80 #10-20');
    await tester.enterText(notesField, 'Timbre rojo');
    await tester.tap(find.text('Sandbox DTS (simulado)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_order_button')));
    await tester.pumpAndSettle();

    // Sandbox sheet appears for method_type=sandbox; close without calling API.
    if (find.text('Sandbox DTS').evaluate().isNotEmpty) {
      Navigator.of(tester.element(find.text('Sandbox DTS'))).pop(false);
      await tester.pumpAndSettle();
    }

    expect(captured, isNotNull);
    expect(captured!.storeId, 1);
    expect(captured!.deliveryAddress, 'Calle 80 #10-20');
    expect(captured!.customerNotes, 'Timbre rojo');
    expect(captured!.paymentMethodId, 7);
    expect(captured!.items.single.productId, 10);
    expect(captured!.items.single.quantity, 1);
  });

  testWidgets('checkout_shows_api_error_detail_test', (tester) async {
    when(() => createOrderUseCase(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/orders/'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/orders/'),
          statusCode: 400,
          data: {'detail': 'Tu dirección está fuera de la zona de entrega'},
        ),
      ),
    );

    final apiClient = _apiClientWithHandlers();
    await pumpCheckout(tester, apiClient: apiClient);

    await tester.enterText(find.byType(TextField).first, 'Calle lejos');
    await tester.tap(find.byKey(const Key('confirm_order_button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Tu dirección está fuera de la zona de entrega'),
      findsOneWidget,
    );
    expect(find.text('No se pudo crear el pedido'), findsNothing);
  });
}
