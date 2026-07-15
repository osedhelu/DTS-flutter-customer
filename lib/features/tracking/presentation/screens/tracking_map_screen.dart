import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/di/repository_providers.dart';
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
            onPressed: () {
              // Route registered when chat feature lands on customer.
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _CustomerOrderChatPlaceholder(
                    orderId: widget.orderId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading && _tracking == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    statusLabel,
                    key: const Key('tracking_status'),
                    style: Theme.of(context).textTheme.titleMedium,
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

class _CustomerOrderChatPlaceholder extends ConsumerStatefulWidget {
  const _CustomerOrderChatPlaceholder({required this.orderId});

  final int orderId;

  @override
  ConsumerState<_CustomerOrderChatPlaceholder> createState() =>
      _CustomerOrderChatPlaceholderState();
}

class _CustomerOrderChatPlaceholderState
    extends ConsumerState<_CustomerOrderChatPlaceholder> {
  final _controller = TextEditingController();
  final _messages = <Map<String, dynamic>>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/orders/${widget.orderId}/messages/');
      final list = (res.data as List).cast<dynamic>();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(list.map((e) => Map<String, dynamic>.from(e as Map)));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.post(
        '/orders/${widget.orderId}/messages/',
        data: {'body': text},
      );
      _controller.clear();
      if (!mounted) return;
      setState(() {
        _messages.add(Map<String, dynamic>.from(res.data as Map));
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat #${widget.orderId}')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      return ListTile(
                        title: Text('${m['sender_role']}: ${m['body']}'),
                        dense: true,
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
