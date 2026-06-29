import '../../domain/entities/order.dart';

class OrderDto {
  const OrderDto({
    required this.id,
    required this.storeId,
    required this.status,
    required this.total,
    required this.orderType,
    this.serviceAddress,
    this.customerNotes,
    this.scheduledAt,
    this.durationMinutes,
  });

  final int id;
  final int storeId;
  final String status;
  final double total;
  final String orderType;
  final String? serviceAddress;
  final String? customerNotes;
  final DateTime? scheduledAt;
  final int? durationMinutes;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['id'] as int,
      storeId: json['store_id'] as int,
      status: json['status'] as String,
      total: double.parse(json['total'].toString()),
      orderType: json['order_type'] as String,
      serviceAddress: json['service_address'] as String?,
      customerNotes: json['customer_notes'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int?,
    );
  }

  Order toEntity() => Order(
        id: id,
        storeId: storeId,
        status: status,
        total: total,
        orderType: orderType,
        serviceAddress: serviceAddress,
        customerNotes: customerNotes,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
      );
}
