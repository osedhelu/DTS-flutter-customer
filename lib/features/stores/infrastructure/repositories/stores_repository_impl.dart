import '../../domain/entities/store.dart';
import '../../domain/repositories/stores_repository.dart';
import '../datasources/stores_remote_datasource.dart';

class StoresRepositoryImpl implements StoresRepository {
  const StoresRepositoryImpl({required StoresRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final StoresRemoteDataSource _remoteDataSource;

  @override
  Future<List<Store>> getStores() async {
    final dtos = await _remoteDataSource.fetchStores();
    return dtos.map((dto) => dto.toEntity()).toList();
  }
}
