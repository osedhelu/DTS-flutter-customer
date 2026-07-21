import 'package:equatable/equatable.dart';

class Order extends Equatable {
  const Order({
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

  bool get isService => orderType.toUpperCase() == 'SERVICE';

  bool get isActive =>
      status != 'delivered' &&
      status != 'cancelled' &&
      status != 'rejected';

  String get addressLabel =>
      deliveryAddress ?? serviceAddress ?? '';

  @override
  List<Object?> get props => [
        id,
        storeId,
        status,
        total,
        orderType,
        storeName,
        deliveryAddress,
        driverName,
      ];
}

class CreateOrderItem {
  const CreateOrderItem({
    required this.productId,
    required this.quantity,
  });

  final int productId;
  final int quantity;
}

class CreateOrderParams {
  const CreateOrderParams({
    required this.storeId,
    required this.items,
    this.deliveryAddress,
    this.customerNotes,
    this.latitude,
    this.longitude,
    this.paymentMethodId,
    this.couponCode,
  });

  final int storeId;
  final List<CreateOrderItem> items;
  final String? deliveryAddress;
  final String? customerNotes;
  final double? latitude;
  final double? longitude;
  final int? paymentMethodId;
  final String? couponCode;
}

class CreateServiceOrderParams {
  const CreateServiceOrderParams({
    required this.storeId,
    required this.items,
    required this.serviceAddress,
    this.customerNotes,
    this.scheduledAt,
    this.latitude,
    this.longitude,
    this.paymentMethodId,
    this.couponCode,
  });

  final int storeId;
  final List<CreateOrderItem> items;
  final String serviceAddress;
  final String? customerNotes;
  final DateTime? scheduledAt;
  final double? latitude;
  final double? longitude;
  final int? paymentMethodId;
  final String? couponCode;
}
