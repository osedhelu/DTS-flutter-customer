import 'package:dio/dio.dart';

import '../../domain/entities/order.dart';
import '../models/order_dto.dart';

class OrdersRemoteDataSource {
  const OrdersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<OrderDto>> listOrders({String? status}) async {
    final response = await _dio.get<dynamic>(
      '/orders/',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final data = response.data;
    final List<dynamic> results;
    if (data is Map<String, dynamic>) {
      results = data['results'] as List<dynamic>? ?? [];
    } else if (data is List<dynamic>) {
      results = data;
    } else {
      results = [];
    }
    return results
        .map((e) => OrderDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderDto> createOrder(CreateOrderParams params) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders/',
      data: {
        'store_id': params.storeId,
        'items': params.items
            .map((item) => {
                  'product_id': item.productId,
                  'quantity': item.quantity,
                })
            .toList(),
        if (params.deliveryAddress != null)
          'delivery_address': params.deliveryAddress,
        if (params.customerNotes != null)
          'customer_notes': params.customerNotes,
        if (params.latitude != null) 'latitude': params.latitude,
        if (params.longitude != null) 'longitude': params.longitude,
        if (params.paymentMethodId != null && params.paymentMethodId != 0)
          'payment_method_id': params.paymentMethodId,
        if (params.couponCode != null && params.couponCode!.isNotEmpty)
          'coupon_code': params.couponCode,
      },
    );
    return OrderDto.fromJson(response.data!);
  }

  Future<OrderDto> createServiceOrder(CreateServiceOrderParams params) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders/service/',
      data: {
        'store_id': params.storeId,
        'items': params.items
            .map((item) => {
                  'product_id': item.productId,
                  'quantity': item.quantity,
                })
            .toList(),
        'service_address': params.serviceAddress,
        if (params.customerNotes != null) 'customer_notes': params.customerNotes,
        if (params.scheduledAt != null)
          'scheduled_at': params.scheduledAt!.toIso8601String(),
        if (params.latitude != null) 'latitude': params.latitude,
        if (params.longitude != null) 'longitude': params.longitude,
        if (params.paymentMethodId != null && params.paymentMethodId != 0)
          'payment_method_id': params.paymentMethodId,
        if (params.couponCode != null && params.couponCode!.isNotEmpty)
          'coupon_code': params.couponCode,
      },
    );
    return OrderDto.fromJson(response.data!);
  }

  Future<OrderDto> fetchOrder(int orderId) async {
    final response = await _dio.get<Map<String, dynamic>>('/orders/$orderId/');
    return OrderDto.fromJson(response.data!);
  }

  Future<OrderDto> cancelOrder(int orderId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/orders/$orderId/',
      data: {'status': 'cancelled'},
    );
    return OrderDto.fromJson(response.data!);
  }

  Future<bool> fetchSandboxEnabled() async {
    final response = await _dio.get<Map<String, dynamic>>('/sandbox-config/');
    return response.data?['enabled'] as bool? ?? false;
  }

  Future<Map<String, dynamic>> sandboxPay({
    required int orderId,
    required String cardLast4,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/sandbox-pay/',
      data: {'card_last4': cardLast4},
    );
    return response.data!;
  }
}
