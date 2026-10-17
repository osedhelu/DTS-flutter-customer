import '../entities/ride.dart';
import '../repositories/rides_repository.dart';

class ListRidesUseCase {
  const ListRidesUseCase(this._repository);

  final RidesRepository _repository;

  Future<List<Ride>> call() => _repository.listRides();
}
