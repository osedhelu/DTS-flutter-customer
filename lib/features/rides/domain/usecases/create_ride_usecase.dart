import '../entities/ride.dart';
import '../entities/ride_request.dart';
import '../repositories/rides_repository.dart';

class CreateRideUseCase {
  const CreateRideUseCase(this._repository);

  final RidesRepository _repository;

  Future<Ride> call(CreateRideParams params) => _repository.createRide(params);
}
