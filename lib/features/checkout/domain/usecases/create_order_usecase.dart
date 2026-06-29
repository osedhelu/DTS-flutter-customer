import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class CreateOrderUseCase {
  const CreateOrderUseCase(this._repository);

  final OrdersRepository _repository;

  Future<Order> call(CreateOrderParams params) => _repository.createOrder(params);
}
