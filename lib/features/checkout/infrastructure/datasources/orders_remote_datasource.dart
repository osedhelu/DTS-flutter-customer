import 'package:dio/dio.dart';

import '../../domain/entities/order.dart';
import '../models/order_dto.dart';

class OrdersRemoteDataSource {
  const OrdersRemoteDataSource(this._dio);

  final Dio _dio;

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
      },
    );
    return OrderDto.fromJson(response.data!);
  }

  Future<OrderDto> fetchOrder(int orderId) async {
    final response = await _dio.get<Map<String, dynamic>>('/orders/$orderId/');
    return OrderDto.fromJson(response.data!);
  }
}
