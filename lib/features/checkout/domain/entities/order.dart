import 'package:equatable/equatable.dart';

class Order extends Equatable {
  const Order({
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

  bool get isService => orderType.toUpperCase() == 'SERVICE';

  @override
  List<Object?> get props => [
        id,
        storeId,
        status,
        total,
        orderType,
        serviceAddress,
        customerNotes,
        scheduledAt,
        durationMinutes,
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
  });

  final int storeId;
  final List<CreateOrderItem> items;
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
  });

  final int storeId;
  final List<CreateOrderItem> items;
  final String serviceAddress;
  final String? customerNotes;
  final DateTime? scheduledAt;
  final double? latitude;
  final double? longitude;
}
