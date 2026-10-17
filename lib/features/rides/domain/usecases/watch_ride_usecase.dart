import '../entities/ride_tracking_update.dart';
import '../repositories/rides_repository.dart';

class WatchRideUseCase {
  const WatchRideUseCase(this._repository);

  final RidesRepository _repository;

  Stream<RideTrackingUpdate> call(int rideId) => _repository.watchRide(rideId);
}
