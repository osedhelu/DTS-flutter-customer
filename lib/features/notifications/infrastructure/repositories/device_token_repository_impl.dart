import '../../domain/repositories/device_token_repository.dart';
import '../datasources/device_token_remote_datasource.dart';

class DeviceTokenRepositoryImpl implements DeviceTokenRepository {
  const DeviceTokenRepositoryImpl({
    required DeviceTokenRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DeviceTokenRemoteDataSource _remoteDataSource;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
  }) {
    return _remoteDataSource.registerToken(token: token, platform: platform);
  }
}
