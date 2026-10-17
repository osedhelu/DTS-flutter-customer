import '../entities/ride.dart';
import '../repositories/rides_repository.dart';

class GetRideUseCase {
  const GetRideUseCase(this._repository);

  final RidesRepository _repository;

  Future<Ride> call(int rideId) => _repository.getRide(rideId);
}
