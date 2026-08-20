import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/tracking_data.dart';

typedef MapWidgetBuilder = Widget Function({
  required LatLng? driverPosition,
  required LatLng? destinationPosition,
  required String status,
  List<LatLng> routePoints,
});

final mapWidgetBuilderProvider = Provider<MapWidgetBuilder>((ref) {
  return ({
    required LatLng? driverPosition,
    required LatLng? destinationPosition,
    required String status,
    List<LatLng> routePoints = const [],
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

    final polylines = <Polyline>{};
    if (routePoints.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('tracking_route'),
          points: routePoints,
          color: const Color(0xFF3b82f6),
          width: 5,
        ),
      );
    }

    final initial =
        driverPosition ?? destinationPosition ?? const LatLng(4.711, -74.0721);

    return GoogleMap(
      key: const Key('tracking_map'),
      initialCameraPosition: CameraPosition(target: initial, zoom: 14),
      markers: markers,
      polylines: polylines,
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
  StreamSubscription? _wsSubscription;
  TrackingData? _tracking;
  String? _error;
  bool _loading = true;
  List<LatLng> _routePolyline = const [];
  String? _lastStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadTracking();
      await _connectWebSocket();
      if (!mounted) return;
      // Polling de respaldo hasta el primer mensaje WS.
      _pollTimer ??= Timer.periodic(
        const Duration(seconds: 8),
        (_) => _loadTracking(),
      );
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _wsSubscription?.cancel();
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
      if (!tracking.shouldShowDriverLive) {
        await _stopLiveUpdates();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _stopLiveUpdates() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    await _wsSubscription?.cancel();
    _wsSubscription = null;
  }

  Future<void> _connectWebSocket() async {
    if (_tracking != null && !_tracking!.shouldShowDriverLive) return;

    final token = await ref.read(tokenStorageProvider).getAccessToken();
    if (token == null || token.isEmpty || !mounted) return;

    try {
      final stream = ref.read(trackingWsDataSourceProvider).watchLocations(
            orderId: widget.orderId,
            accessToken: token,
          );
      _wsSubscription = stream.listen(
        (update) {
          if (!mounted) return;
          final nextStatus =
              update.orderStatus ?? _tracking?.status ?? 'on_the_way';
          final nextRoutePolyline = update.polylinePoints ?? _routePolyline;
          setState(() {
            // Mantener poll ligero para status/destino (C19: no congelar status).
            _tracking = TrackingData(
              orderId: update.orderId,
              status: nextStatus,
              driverLatitude: update.latitude ?? _tracking?.driverLatitude,
              driverLongitude: update.longitude ?? _tracking?.driverLongitude,
              destinationLatitude:
                  update.destinationLatitude ?? _tracking?.destinationLatitude,
              destinationLongitude: update.destinationLongitude ??
                  _tracking?.destinationLongitude,
              updatedAt: update.recordedAt,
              isLive: true,
              etaMinutes: update.etaMinutes ?? _tracking?.etaMinutes,
            );
            _routePolyline = nextRoutePolyline;
            _loading = false;
            _error = null;
          });
          if (_lastStatus != null && _lastStatus != nextStatus) {
            _showStatusChangeSnackbar(nextStatus);
          }
          _lastStatus = nextStatus;
        },
        onError: (_) {
          if (!mounted) return;
          if (_tracking?.shouldShowDriverLive ?? true) {
            _pollTimer ??= Timer.periodic(
              const Duration(seconds: 8),
              (_) => _loadTracking(),
            );
          }
        },
        onDone: () {},
        cancelOnError: false,
      );
    } catch (_) {
      // Fallback a polling si el WS no conecta.
    }
  }

  void _showStatusChangeSnackbar(String status) {
    final message = switch (status) {
      'driver_assigned' ||
      'DRIVER_ASSIGNED' =>
        'Un conductor está en camino al comercio',
      'picked_up' || 'PICKED_UP' => 'El conductor recogió tu pedido',
      'on_the_way' || 'ON_THE_WAY' => 'Tu pedido está en camino',
      'delivered' || 'DELIVERED' => 'Pedido entregado',
      _ => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapBuilder = ref.watch(mapWidgetBuilderProvider);
    final live = _tracking?.shouldShowDriverLive ?? true;
    final statusLabel = live
        ? (_tracking?.status ?? _error ?? 'Cargando...')
        : 'Entrega finalizada (${_tracking?.status ?? ''})';

    return Scaffold(
      appBar: AppBar(
        title: Text('Seguimiento #${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat',
            onPressed: () => context.push('/orders/${widget.orderId}/chat'),
          ),
        ],
      ),
      body: _loading && _tracking == null
          ? const DtsLoading()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        key: const Key('tracking_status'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_tracking?.etaMinutes != null)
                        Text(
                          'Llega en ~${_tracking!.etaMinutes} min',
                          key: const Key('tracking_eta'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: mapBuilder(
                    driverPosition: live
                        ? _latLng(
                            _tracking?.driverLatitude,
                            _tracking?.driverLongitude,
                          )
                        : null,
                    destinationPosition: _latLng(
                      _tracking?.destinationLatitude,
                      _tracking?.destinationLongitude,
                    ),
                    status: _tracking?.status ?? '',
                    routePoints: live ? _routePolyline : const [],
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
