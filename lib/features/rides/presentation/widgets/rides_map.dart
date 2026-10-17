import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Constructor del widget de mapa de viajes.
///
/// Se inyecta vía provider para poder sustituir GoogleMap en tests de widgets
/// (mismo patrón que `mapWidgetBuilderProvider` del tracking).
typedef RidesMapBuilder = Widget Function({
  required LatLng? pickupPosition,
  required LatLng? dropoffPosition,
  required LatLng? driverPosition,
  ValueChanged<LatLng>? onMapTap,
});

const LatLng defaultRideCenter = LatLng(4.7110, -74.0721);

final ridesMapBuilderProvider = Provider<RidesMapBuilder>((ref) {
  return ({
    required LatLng? pickupPosition,
    required LatLng? dropoffPosition,
    required LatLng? driverPosition,
    ValueChanged<LatLng>? onMapTap,
  }) {
    final markers = <Marker>{};
    if (pickupPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('ride_pickup'),
          position: pickupPosition,
          infoWindow: const InfoWindow(title: 'Origen'),
        ),
      );
    }
    if (dropoffPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('ride_dropoff'),
          position: dropoffPosition,
          infoWindow: const InfoWindow(title: 'Destino'),
        ),
      );
    }
    if (driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('ride_driver'),
          position: driverPosition,
          infoWindow: const InfoWindow(title: 'Conductor'),
        ),
      );
    }

    final initial = pickupPosition ??
        dropoffPosition ??
        driverPosition ??
        defaultRideCenter;

    return GoogleMap(
      key: const Key('rides_map'),
      initialCameraPosition: CameraPosition(target: initial, zoom: 14),
      markers: markers,
      onTap: onMapTap,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  };
});
