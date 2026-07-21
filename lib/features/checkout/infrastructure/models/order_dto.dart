import '../../domain/entities/order.dart';

class OrderDto {
  const OrderDto({
    required this.id,
    required this.storeId,
    required this.status,
    required this.total,
    required this.orderType,
    this.storeName = '',
    this.serviceAddress,
    this.deliveryAddress,
    this.customerNotes,
    this.scheduledAt,
    this.durationMinutes,
    this.driverName,
    this.driverPhone,
    this.itemCount = 0,
  });

  final int id;
  final int storeId;
  final String status;
  final double total;
  final String orderType;
  final String storeName;
  final String? serviceAddress;
  final String? deliveryAddress;
  final String? customerNotes;
  final DateTime? scheduledAt;
  final int? durationMinutes;
  final String? driverName;
  final String? driverPhone;
  final int itemCount;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['id'] as int,
      storeId: json['store_id'] as int,
      status: json['status'] as String,
      total: double.parse(json['total'].toString()),
      orderType: json['order_type'] as String? ?? 'DELIVERY',
      storeName: json['store_name'] as String? ?? '',
      serviceAddress: json['service_address'] as String?,
      deliveryAddress: json['delivery_address'] as String? ??
          json['service_address'] as String?,
      customerNotes: json['customer_notes'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int?,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      itemCount: json['item_count'] as int? ?? 0,
    );
  }

  Order toEntity() => Order(
        id: id,
        storeId: storeId,
        status: status,
        total: total,
        orderType: orderType,
        storeName: storeName,
        serviceAddress: serviceAddress,
        deliveryAddress: deliveryAddress,
        customerNotes: customerNotes,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        driverName: driverName,
        driverPhone: driverPhone,
        itemCount: itemCount,
      );
}
