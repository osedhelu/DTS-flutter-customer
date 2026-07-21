import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapAddressPicker extends StatefulWidget {
  const MapAddressPicker({
    super.key,
    required this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  final String initialAddress;
  final double? initialLat;
  final double? initialLng;

  @override
  State<MapAddressPicker> createState() => _MapAddressPickerState();
}

class _MapAddressPickerState extends State<MapAddressPicker> {
  late LatLng _position;
  final _addressController = TextEditingController();
  bool _loading = true;
  bool _locationEnabled = false;
  String? _locationHint;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress;
    _position = LatLng(
      widget.initialLat ?? 4.711,
      widget.initialLng ?? -74.0721,
    );
    _initLocation();
  }

  Future<void> _initLocation() async {
    if (widget.initialLat != null && widget.initialLng != null) {
      setState(() {
        _loading = false;
        _locationEnabled = true;
      });
      return;
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _locationHint =
              'Activa el GPS para centrar el mapa en tu ubicación.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _locationHint =
              'Sin permiso de ubicación: puedes mover el pin manualmente.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = LatLng(pos.latitude, pos.longitude);
        _loading = false;
        _locationEnabled = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _locationHint = 'No se pudo obtener GPS. Usa el pin en el mapa.';
        });
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubicación de entrega'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            const SizedBox(height: 12),
            if (_locationHint != null) ...[
              Text(
                _locationHint!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: 220,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition:
                          CameraPosition(target: _position, zoom: 15),
                      markers: {
                        Marker(
                          markerId: const MarkerId('delivery'),
                          position: _position,
                          draggable: true,
                          onDragEnd: (p) => setState(() => _position = p),
                        ),
                      },
                      onTap: (p) => setState(() => _position = p),
                      myLocationEnabled: _locationEnabled,
                      myLocationButtonEnabled: _locationEnabled,
                      zoomControlsEnabled: false,
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'address': _addressController.text.trim(),
              'latitude': _position.latitude,
              'longitude': _position.longitude,
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
