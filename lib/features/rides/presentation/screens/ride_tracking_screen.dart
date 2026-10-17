import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../checkout/presentation/utils/api_error_detail.dart';
import '../../application/providers/rides_providers.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_tracking_update.dart';
import '../widgets/ride_status_card.dart';
import '../widgets/rides_map.dart';

/// Seguimiento en tiempo real del viaje (conductor vía WebSocket + polling).
class RideTrackingScreen extends ConsumerStatefulWidget {
  const RideTrackingScreen({super.key, required this.rideId});

  final int rideId;

  @override
  ConsumerState<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends ConsumerState<RideTrackingScreen> {
  Ride? _ride;
  bool _loading = true;
  bool _cancelling = false;
  String? _error;
  LatLng? _driverPoint;
  LatLng? _destinationPoint;
  int? _etaMinutes;
  StreamSubscription<RideTrackingUpdate>? _wsSub;
  Timer? _pollTimer;
  bool _wsClosed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _subscribeWs();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && !(_ride?.status.isTerminal ?? false)) {
        unawaited(_load(silent: true));
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final ride = await ref.read(getRideUseCaseProvider).call(widget.rideId);
      if (!mounted) return;
      setState(() {
        _ride = ride;
        _loading = false;
        _error = null;
        _destinationPoint = LatLng(
          ride.dropoff.latitude,
          ride.dropoff.longitude,
        );
        _etaMinutes ??= ride.estimatedDurationMinutes;
      });
      if (ride.status.isTerminal) _closeLiveUpdates();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _error = parseApiErrorDetail(
            error,
            fallback: 'No pudimos cargar el viaje.',
          );
        }
        _loading = false;
      });
    }
  }

  void _subscribeWs() {
    _wsSub = ref.read(watchRideUseCaseProvider).call(widget.rideId).listen(
      (update) {
        if (!mounted) return;
        setState(() {
          if (update.driverLatitude != null && update.driverLongitude != null) {
            _driverPoint = LatLng(
              update.driverLatitude!,
              update.driverLongitude!,
            );
          }
          if (update.destinationLatitude != null &&
              update.destinationLongitude != null) {
            _destinationPoint = LatLng(
              update.destinationLatitude!,
              update.destinationLongitude!,
            );
          }
          if (update.etaMinutes != null) _etaMinutes = update.etaMinutes;
          final status = update.status;
          if (status != null && _ride != null) {
            _ride = _ride!.copyWith(status: status);
          }
        });
        if (update.status?.isTerminal ?? false) _closeLiveUpdates();
      },
      onError: (_) {
        // Silencioso: el polling mantiene el estado actualizado.
      },
    );
  }

  void _closeLiveUpdates() {
    if (_wsClosed) return;
    _wsClosed = true;
    _wsSub?.cancel();
    _pollTimer?.cancel();
  }

  Future<void> _cancelRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar viaje?'),
        content: const Text('Se cancelará la búsqueda del conductor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            key: const Key('confirm_cancel_ride'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final ride =
          await ref.read(cancelRideUseCaseProvider).call(widget.rideId);
      if (!mounted) return;
      setState(() {
        _ride = ride;
        _cancelling = false;
      });
      _closeLiveUpdates();
    } catch (error) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parseApiErrorDetail(error,
                fallback: 'No pudimos cancelar el viaje.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('ride_tracking_screen'),
      appBar: AppBar(title: const Text('Tu viaje')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const DtsLoading(message: 'Cargando viaje…');
    final ride = _ride;
    if (ride == null) {
      return DtsErrorView(
        message: _error ?? 'No pudimos cargar el viaje.',
        onRetry: _load,
      );
    }

    final mapBuilder = ref.watch(ridesMapBuilderProvider);
    final pickupPoint = LatLng(ride.pickup.latitude, ride.pickup.longitude);
    final destination = _destinationPoint ??
        LatLng(ride.dropoff.latitude, ride.dropoff.longitude);

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.38,
          child: mapBuilder(
            pickupPosition: pickupPoint,
            dropoffPosition: destination,
            driverPosition: _driverPoint,
            onMapTap: null,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              RideStatusCard(
                status: ride.status,
                etaMinutes: _etaMinutes,
                driverName: ride.hasDriver ? 'Tu conductor' : null,
              ),
              if (ride.status.canCancel) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  key: const Key('cancel_ride_button'),
                  onPressed: _cancelling ? null : _cancelRide,
                  icon: _cancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close),
                  label: const Text('Cancelar viaje'),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _TotalRow(total: ride.total),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Total estimado', style: theme.textTheme.bodyMedium),
        Text(
          '\$${total.toStringAsFixed(2)}',
          key: const Key('ride_total'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
