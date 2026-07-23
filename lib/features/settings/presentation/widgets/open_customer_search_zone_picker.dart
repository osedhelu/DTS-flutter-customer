import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/location_radius_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../profile/domain/entities/customer_profile.dart';
import '../../../stores/application/providers/featured_products_provider.dart';
import '../../../stores/application/providers/stores_providers.dart';
import 'location_radius_picker.dart';

Future<CustomerProfile> resolveCustomerPickerCenter(
  WidgetRef ref,
  CustomerProfile profile,
) async {
  if (profile.hasSearchCenter) {
    return profile;
  }

  try {
    final addresses =
        await ref.read(customerProfileRemoteDataSourceProvider).listAddresses();
    CustomerAddress? preferred;
    for (final address in addresses) {
      if (address.latitude == null || address.longitude == null) {
        continue;
      }
      if (address.isDefault) {
        preferred = address;
        break;
      }
      preferred ??= address;
    }
    if (preferred == null) {
      return profile;
    }
    return CustomerProfile(
      fullName: profile.fullName,
      email: profile.email,
      phone: profile.phone,
      photoUrl: profile.photoUrl,
      defaultAddress: profile.defaultAddress,
      searchCenterLatitude: preferred.latitude,
      searchCenterLongitude: preferred.longitude,
      searchRadiusKm: profile.searchRadiusKm,
    );
  } catch (_) {
    return profile;
  }
}

Future<CustomerProfile?> openCustomerSearchZonePicker(
  BuildContext context,
  WidgetRef ref, {
  CustomerProfile? profile,
}) async {
  profile ??=
      await ref.read(customerProfileRemoteDataSourceProvider).getProfile();
  final seeded = await resolveCustomerPickerCenter(ref, profile);

  final result = await LocationRadiusPicker.show(
    context,
    initialLatitude: seeded.searchCenterLatitude,
    initialLongitude: seeded.searchCenterLongitude,
    initialRadiusKm: seeded.searchRadiusKm,
  );
  if (result == null || !context.mounted) return null;

  try {
    final updated =
        await ref.read(customerProfileRemoteDataSourceProvider).updateProfile(
              searchCenterLatitude: result.latitude,
              searchCenterLongitude: result.longitude,
              searchRadiusKm: result.radiusKm,
            );
    ref.invalidate(customerSearchProfileProvider);
    ref.invalidate(storesListProvider);
    ref.invalidate(featuredProductsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Radio de tiendas: ${normalizeRadiusPreset(updated.searchRadiusKm).toStringAsFixed(0)} km',
          ),
        ),
      );
    }
    return updated;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la ubicación: $e')),
      );
    }
    return null;
  }
}
