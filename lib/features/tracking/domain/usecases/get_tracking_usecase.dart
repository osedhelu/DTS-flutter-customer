import '../entities/tracking_data.dart';
import '../repositories/tracking_repository.dart';

class GetTrackingUseCase {
  const GetTrackingUseCase(this._repository);

  final TrackingRepository _repository;

  Future<TrackingData> call(int orderId) => _repository.getTracking(orderId);
}
