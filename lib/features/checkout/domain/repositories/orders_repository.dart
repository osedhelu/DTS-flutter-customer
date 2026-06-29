import '../entities/order.dart';

abstract class OrdersRepository {
  Future<Order> createOrder(CreateOrderParams params);

  Future<Order> createServiceOrder(CreateServiceOrderParams params);

  Future<Order> getOrder(int orderId);
}
