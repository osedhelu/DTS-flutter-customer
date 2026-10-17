import '../entities/ride.dart';
import '../repositories/rides_repository.dart';

class CancelRideUseCase {
  const CancelRideUseCase(this._repository);

  final RidesRepository _repository;

  Future<Ride> call(int rideId) => _repository.cancelRide(rideId);
}
