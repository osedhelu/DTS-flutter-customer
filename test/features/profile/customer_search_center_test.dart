import 'package:dts_customer/features/profile/domain/entities/customer_profile.dart';
import 'package:dts_customer/features/stores/application/providers/stores_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CustomerProfile expone centro de búsqueda', () {
    const profile = CustomerProfile(
      fullName: 'Luis',
      email: 'luis@test.com',
      phone: '+57300',
      photoUrl: '',
      defaultAddress: 'Calle 1',
      searchCenterLatitude: 4.65,
      searchCenterLongitude: -74.08,
      searchRadiusKm: 20,
    );

    expect(profile.hasSearchCenter, isTrue);

    final location = resolveStoreSearchLocation(profile);
    expect(location?.latitude, 4.65);
    expect(location?.longitude, -74.08);
    expect(location?.radiusKm, 20);
  });

  test('resolveStoreSearchLocation retorna null sin centro', () {
    const profile = CustomerProfile(
      fullName: 'Luis',
      email: 'luis@test.com',
      phone: '+57300',
      photoUrl: '',
      defaultAddress: 'Calle 1',
    );

    expect(resolveStoreSearchLocation(profile), isNull);
  });
}
