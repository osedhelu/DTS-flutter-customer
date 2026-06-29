import '../../domain/entities/tracking_data.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_remote_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  const TrackingRepositoryImpl({required TrackingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final TrackingRemoteDataSource _remoteDataSource;

  @override
  Future<TrackingData> getTracking(int orderId) async {
    final dto = await _remoteDataSource.fetchTracking(orderId);
    return dto.toEntity();
  }
}
