import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../profile/domain/entities/customer_profile.dart';
import '../../domain/entities/store.dart';
import '../../domain/usecases/get_stores_usecase.dart';

final getStoresUseCaseProvider = Provider<GetStoresUseCase>((ref) {
  return GetStoresUseCase(ref.watch(storesRepositoryProvider));
});

final storesListProvider = FutureProvider<List<Store>>((ref) async {
  final profile = await ref.watch(customerSearchProfileProvider.future);
  final location = resolveStoreSearchLocation(profile);
  return ref.watch(getStoresUseCaseProvider).call(
        latitude: location?.latitude,
        longitude: location?.longitude,
        radiusKm: location?.radiusKm,
      );
});

final customerSearchProfileProvider =
    FutureProvider<CustomerProfile>((ref) async {
  return ref.watch(customerProfileRemoteDataSourceProvider).getProfile();
});

class StoreSearchLocation {
  const StoreSearchLocation({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });

  final double latitude;
  final double longitude;
  final double radiusKm;
}

StoreSearchLocation? resolveStoreSearchLocation(CustomerProfile profile) {
  if (profile.hasSearchCenter) {
    return StoreSearchLocation(
      latitude: profile.searchCenterLatitude!,
      longitude: profile.searchCenterLongitude!,
      radiusKm: profile.searchRadiusKm,
    );
  }
  return null;
}
