import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class CreateServiceOrderUseCase {
  const CreateServiceOrderUseCase(this._repository);

  final OrdersRepository _repository;

  Future<Order> call(CreateServiceOrderParams params) =>
      _repository.createServiceOrder(params);
}
