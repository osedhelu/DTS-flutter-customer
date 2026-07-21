import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl({required OrdersRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final OrdersRemoteDataSource _remoteDataSource;

  @override
  Future<List<Order>> listOrders({String? status}) async {
    final dtos = await _remoteDataSource.listOrders(status: status);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Order> createOrder(CreateOrderParams params) async {
    final dto = await _remoteDataSource.createOrder(params);
    return dto.toEntity();
  }

  @override
  Future<Order> createServiceOrder(CreateServiceOrderParams params) async {
    final dto = await _remoteDataSource.createServiceOrder(params);
    return dto.toEntity();
  }

  @override
  Future<Order> getOrder(int orderId) async {
    final dto = await _remoteDataSource.fetchOrder(orderId);
    return dto.toEntity();
  }

  @override
  Future<Order> cancelOrder(int orderId) async {
    final dto = await _remoteDataSource.cancelOrder(orderId);
    return dto.toEntity();
  }
}
