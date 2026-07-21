import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_customer/features/checkout/domain/entities/order.dart';
import 'package:dts_customer/features/checkout/domain/repositories/orders_repository.dart';
import 'package:dts_customer/features/checkout/domain/usecases/create_order_usecase.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late MockOrdersRepository repository;
  late CreateOrderUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      const CreateOrderParams(
        storeId: 0,
        items: [CreateOrderItem(productId: 0, quantity: 1)],
      ),
    );
  });

  setUp(() {
    repository = MockOrdersRepository();
    useCase = CreateOrderUseCase(repository);
  });

  test('create_order_usecase_test', () async {
    const order = Order(
      id: 99,
      storeId: 1,
      status: 'PENDING',
      total: 20,
      orderType: 'PHYSICAL',
    );

    when(() => repository.createOrder(any())).thenAnswer((_) async => order);

    final result = await useCase(
      const CreateOrderParams(
        storeId: 1,
        items: [CreateOrderItem(productId: 5, quantity: 2)],
      ),
    );

    expect(result.id, 99);
    verify(() => repository.createOrder(any())).called(1);
  });

  test('create_order_usecase_propagates_error_test', () async {
    when(() => repository.createOrder(any())).thenThrow(
      Exception('stock insuficiente'),
    );

    expect(
      () => useCase(
        const CreateOrderParams(
          storeId: 1,
          items: [CreateOrderItem(productId: 5, quantity: 2)],
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
