import '../entities/order.dart';

abstract class OrdersRepository {
  Future<List<Order>> listOrders({String? status});

  Future<Order> createOrder(CreateOrderParams params);

  Future<Order> createServiceOrder(CreateServiceOrderParams params);

  Future<Order> getOrder(int orderId);

  Future<Order> cancelOrder(int orderId);
}
