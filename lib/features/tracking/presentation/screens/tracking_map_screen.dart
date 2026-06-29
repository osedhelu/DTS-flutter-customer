import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/tracking_data.dart';

typedef MapWidgetBuilder = Widget Function({
  required LatLng? driverPosition,
  required LatLng? destinationPosition,
  required String status,
});

final mapWidgetBuilderProvider = Provider<MapWidgetBuilder>((ref) {
  return ({
    required LatLng? driverPosition,
    required LatLng? destinationPosition,
    required String status,
  }) {
    final markers = <Marker>{};
    if (driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPosition,
          infoWindow: const InfoWindow(title: 'Conductor'),
        ),
      );
    }
    if (destinationPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destinationPosition,
          infoWindow: const InfoWindow(title: 'Destino'),
        ),
      );
    }

    final initial = driverPosition ??
        destinationPosition ??
        const LatLng(4.711, -74.0721);

    return GoogleMap(
      key: const Key('tracking_map'),
      initialCameraPosition: CameraPosition(target: initial, zoom: 14),
      markers: markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  };
});

class TrackingMapScreen extends ConsumerStatefulWidget {
  const TrackingMapScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends ConsumerState<TrackingMapScreen> {
  Timer? _pollTimer;
  TrackingData? _tracking;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTracking();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _loadTracking());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTracking() async {
    try {
      final tracking =
          await ref.read(getTrackingUseCaseProvider).call(widget.orderId);
      if (!mounted) return;
      setState(() {
        _tracking = tracking;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapBuilder = ref.watch(mapWidgetBuilderProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Seguimiento #${widget.orderId}')),
      body: _loading && _tracking == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _tracking?.status ?? _error ?? 'Cargando...',
                    key: const Key('tracking_status'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: mapBuilder(
                    driverPosition: _latLng(
                      _tracking?.driverLatitude,
                      _tracking?.driverLongitude,
                    ),
                    destinationPosition: _latLng(
                      _tracking?.destinationLatitude,
                      _tracking?.destinationLongitude,
                    ),
                    status: _tracking?.status ?? '',
                  ),
                ),
              ],
            ),
    );
  }

  LatLng? _latLng(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }
}
