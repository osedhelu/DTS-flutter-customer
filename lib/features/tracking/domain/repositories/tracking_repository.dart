import '../entities/tracking_data.dart';

abstract class TrackingRepository {
  Future<TrackingData> getTracking(int orderId);
}
