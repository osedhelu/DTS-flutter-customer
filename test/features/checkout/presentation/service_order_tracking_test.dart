import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/checkout/domain/entities/order.dart';
import 'package:dts_customer/features/checkout/domain/repositories/orders_repository.dart';
import 'package:dts_customer/features/checkout/presentation/screens/service_order_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late MockOrdersRepository ordersRepository;

  setUp(() {
    ordersRepository = MockOrdersRepository();
  });

  testWidgets('service_order_tracking_test', (tester) async {
    when(() => ordersRepository.getOrder(55)).thenAnswer(
      (_) async => const Order(
        id: 55,
        storeId: 2,
        status: 'IN_PROGRESS',
        total: 50,
        orderType: 'SERVICE',
        serviceAddress: 'Calle 50',
        durationMinutes: 60,
      ),
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(ordersRepository),
        ],
        child: const MaterialApp(
          home: ServiceOrderTrackingScreen(orderId: 55),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('service_order_id')), findsOneWidget);
    expect(find.text('Pedido #55'), findsOneWidget);
    expect(find.byKey(const Key('service_order_status')), findsOneWidget);
    expect(find.text('En curso'), findsOneWidget);
    expect(find.text('Dirección: Calle 50'), findsOneWidget);
  });
}
