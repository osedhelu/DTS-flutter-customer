import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dts_customer/features/checkout/domain/entities/order.dart';
import 'package:dts_customer/features/checkout/infrastructure/datasources/orders_remote_datasource.dart';

void main() {
  test('orders_remote_datasource_create_order_omits_nulls_and_sends_coupon',
      () async {
    Map<String, dynamic>? capturedBody;

    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedBody = Map<String, dynamic>.from(options.data as Map);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'id': 1,
                'store_id': 3,
                'status': 'created',
                'total': '20.00',
                'order_type': 'delivery',
              },
            ),
          );
        },
      ),
    );

    final ds = OrdersRemoteDataSource(dio);
    await ds.createOrder(
      const CreateOrderParams(
        storeId: 3,
        items: [CreateOrderItem(productId: 11, quantity: 2)],
        deliveryAddress: 'Calle 1',
        customerNotes: null,
        latitude: null,
        longitude: null,
        paymentMethodId: null,
        couponCode: 'SAVE10',
      ),
    );

    expect(capturedBody, isNotNull);
    expect(capturedBody!['store_id'], 3);
    expect(capturedBody!['delivery_address'], 'Calle 1');
    expect(capturedBody!.containsKey('latitude'), isFalse);
    expect(capturedBody!.containsKey('longitude'), isFalse);
    expect(capturedBody!.containsKey('payment_method_id'), isFalse);
    expect(capturedBody!.containsKey('customer_notes'), isFalse);
    expect(capturedBody!['coupon_code'], 'SAVE10');
    expect(capturedBody!['items'], [
      {'product_id': 11, 'quantity': 2},
    ]);
  });

  test('orders_remote_datasource_create_order_includes_payment_and_coords',
      () async {
    Map<String, dynamic>? capturedBody;

    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedBody = Map<String, dynamic>.from(options.data as Map);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 201,
              data: {
                'id': 2,
                'store_id': 3,
                'status': 'created',
                'total': '20.00',
                'order_type': 'delivery',
              },
            ),
          );
        },
      ),
    );

    final ds = OrdersRemoteDataSource(dio);
    await ds.createOrder(
      const CreateOrderParams(
        storeId: 3,
        items: [CreateOrderItem(productId: 11, quantity: 1)],
        deliveryAddress: 'Calle 2',
        latitude: 4.7,
        longitude: -74.0,
        paymentMethodId: 9,
      ),
    );

    expect(capturedBody!['latitude'], 4.7);
    expect(capturedBody!['longitude'], -74.0);
    expect(capturedBody!['payment_method_id'], 9);
  });
}
