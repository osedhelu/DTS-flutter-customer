import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../../core/widgets/widgets.dart';
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
  StreamSubscription? _wsSubscription;
  TrackingData? _tracking;
  String? _error;
  bool _loading = true;
  bool _wsActive = false;

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
    if (mounted) {
      setState(() => _wsActive = false);
    }
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
          setState(() {
            _wsActive = true;
            _pollTimer?.cancel();
            _pollTimer = null;
            _tracking = TrackingData(
              orderId: update.orderId,
              status: _tracking?.status ?? 'on_the_way',
              driverLatitude: update.latitude,
              driverLongitude: update.longitude,
              destinationLatitude: _tracking?.destinationLatitude,
              destinationLongitude: _tracking?.destinationLongitude,
              updatedAt: update.recordedAt,
              isLive: true,
            );
            _loading = false;
            _error = null;
          });
        },
        onError: (_) {
          if (!mounted) return;
          _wsActive = false;
          if (_tracking?.shouldShowDriverLive ?? true) {
            _pollTimer ??= Timer.periodic(
              const Duration(seconds: 8),
              (_) => _loadTracking(),
            );
          }
        },
        onDone: () {
          if (!mounted) return;
          _wsActive = false;
        },
        cancelOnError: false,
      );
    } catch (_) {
      _wsActive = false;
    }
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
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
