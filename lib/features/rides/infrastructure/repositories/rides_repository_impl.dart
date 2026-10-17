import '../../../../core/network/token_storage.dart';
import '../../domain/entities/fare_quote.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_request.dart';
import '../../domain/entities/ride_tracking_update.dart';
import '../../domain/repositories/rides_repository.dart';
import '../datasources/rides_remote_datasource.dart';
import '../datasources/rides_ws_datasource.dart';

class RidesRepositoryImpl implements RidesRepository {
  const RidesRepositoryImpl({
    required RidesRemoteDataSource remoteDataSource,
    required RidesWsDataSource wsDataSource,
    required TokenStorage tokenStorage,
  })  : _remoteDataSource = remoteDataSource,
        _wsDataSource = wsDataSource,
        _tokenStorage = tokenStorage;

  final RidesRemoteDataSource _remoteDataSource;
  final RidesWsDataSource _wsDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<FareQuote> quoteRide(QuoteRideParams params) async {
    final dto = await _remoteDataSource.quoteRide(params);
    return dto.toEntity();
  }

  @override
  Future<Ride> createRide(CreateRideParams params) async {
    final dto = await _remoteDataSource.createRide(params);
    return dto.toEntity();
  }

  @override
  Future<Ride> getRide(int rideId) async {
    final dto = await _remoteDataSource.fetchRide(rideId);
    return dto.toEntity();
  }

  @override
  Future<List<Ride>> listRides() async {
    final dtos = await _remoteDataSource.listRides();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<Ride> cancelRide(int rideId) async {
    final dto = await _remoteDataSource.cancelRide(rideId);
    return dto.toEntity();
  }

  @override
  Stream<RideTrackingUpdate> watchRide(int rideId) async* {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return;
    yield* _wsDataSource.watchRide(rideId: rideId, accessToken: token);
  }
}
