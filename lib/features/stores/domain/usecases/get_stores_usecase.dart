import '../entities/store.dart';
import '../repositories/stores_repository.dart';

class GetStoresUseCase {
  const GetStoresUseCase(this._repository);

  final StoresRepository _repository;

  Future<List<Store>> call({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) {
    return _repository.getStores(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }
}
