import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/ride_location.dart';
import '../models/ride_draft.dart';
import '../widgets/pickup_dropoff_picker.dart';
import '../widgets/rides_map.dart';

/// Pantalla principal de movilidad: mapa interactivo + selector origen/destino.
///
/// Es la pestaña predeterminada del [CustomerShellScreen].
class RidesHomeScreen extends ConsumerStatefulWidget {
  const RidesHomeScreen({super.key});

  @override
  ConsumerState<RidesHomeScreen> createState() => _RidesHomeScreenState();
}

class _RidesHomeScreenState extends ConsumerState<RidesHomeScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  LatLng? _pickupPoint;
  LatLng? _dropoffPoint;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // Autodetecta la ubicación al abrir (silencioso: si falla, el usuario puede
    // tocar el mapa o el botón de ubicación).
    unawaited(_useCurrentLocation(forPickup: true, replaceAddress: false));
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _pickupController.text.trim().isNotEmpty &&
      _dropoffController.text.trim().isNotEmpty &&
      _pickupPoint != null &&
      _dropoffPoint != null;

  void _onMapTap(LatLng point) {
    setState(() {
      if (_pickupPoint == null) {
        _pickupPoint = point;
        if (_pickupController.text.trim().isEmpty) {
          _pickupController.text = 'Punto en el mapa';
        }
      } else {
        _dropoffPoint = point;
        if (_dropoffController.text.trim().isEmpty) {
          _dropoffController.text = 'Punto en el mapa';
        }
      }
    });
  }

  Future<void> _useCurrentLocation({
    required bool forPickup,
    required bool replaceAddress,
  }) async {
    if (mounted) setState(() => _locating = true);
    final point = await _resolveCurrentLocation();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (point == null) return;
      if (forPickup) {
        _pickupPoint = point;
        if (replaceAddress || _pickupController.text.trim().isEmpty) {
          _pickupController.text = 'Mi ubicación actual';
        }
      } else {
        _dropoffPoint = point;
        if (replaceAddress || _dropoffController.text.trim().isEmpty) {
          _dropoffController.text = 'Mi ubicación actual';
        }
      }
    });
  }

  Future<LatLng?> _resolveCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      // Sin plugin/permiso (p. ej. tests): se ignora silenciosamente.
      return null;
    }
  }

  void _swap() {
    setState(() {
      final text = _pickupController.text;
      _pickupController.text = _dropoffController.text;
      _dropoffController.text = text;
      final point = _pickupPoint;
      _pickupPoint = _dropoffPoint;
      _dropoffPoint = point;
    });
  }

  void _continue() {
    if (!_canContinue) return;
    final draft = RideDraft(
      pickup: RideLocation(
        address: _pickupController.text.trim(),
        latitude: _pickupPoint!.latitude,
        longitude: _pickupPoint!.longitude,
      ),
      dropoff: RideLocation(
        address: _dropoffController.text.trim(),
        latitude: _dropoffPoint!.latitude,
        longitude: _dropoffPoint!.longitude,
      ),
    );
    context.push('/rides/quote', extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    final mapBuilder = ref.watch(ridesMapBuilderProvider);
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final mapHeight = media.size.height * 0.42;

    return Scaffold(
      key: const Key('rides_home_screen'),
      appBar: AppBar(
        title: const Text('Viajes'),
        actions: [
          IconButton(
            key: const Key('ride_history_button'),
            onPressed: () => context.push('/rides/history'),
            icon: const Icon(Icons.history),
            tooltip: 'Historial de viajes',
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: mapHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: mapBuilder(
                    pickupPosition: _pickupPoint,
                    dropoffPosition: _dropoffPoint,
                    driverPosition: null,
                    onMapTap: _onMapTap,
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: _MapHint(locating: _locating),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PickupDropoffPicker(
                    pickupController: _pickupController,
                    dropoffController: _dropoffController,
                    onUseCurrentPickup: () => _useCurrentLocation(
                      forPickup: true,
                      replaceAddress: true,
                    ),
                    onUseCurrentDropoff: () => _useCurrentLocation(
                      forPickup: false,
                      replaceAddress: true,
                    ),
                    onSwap: _swap,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ListenableBuilder(
                    listenable: Listenable.merge(
                      [_pickupController, _dropoffController],
                    ),
                    builder: (context, _) => DtsPrimaryButton(
                      key: const Key('ride_continue_button'),
                      label: 'Continuar',
                      icon: Icons.arrow_forward,
                      onPressed: _canContinue ? _continue : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Toca el mapa para fijar origen y destino.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.locating});

  final bool locating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (locating)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.touch_app, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                locating ? 'Buscando tu ubicación…' : 'Elige origen y destino',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
