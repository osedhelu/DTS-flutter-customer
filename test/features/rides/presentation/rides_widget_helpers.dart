import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Sustituto de GoogleMap para tests de widgets: no usa el plugin nativo y
/// expone un botón que dispara el tap del mapa (fija origen/destino).
Widget fakeRidesMapBuilder({
  required LatLng? pickupPosition,
  required LatLng? dropoffPosition,
  required LatLng? driverPosition,
  ValueChanged<LatLng>? onMapTap,
}) {
  return ColoredBox(
    color: const Color(0xFFFFE8D6),
    child: Center(
      child: ElevatedButton(
        key: const Key('fake_map_tap'),
        onPressed:
            onMapTap == null ? null : () => onMapTap(const LatLng(4.6, -74.1)),
        child: const Text('fake-map'),
      ),
    ),
  );
}
