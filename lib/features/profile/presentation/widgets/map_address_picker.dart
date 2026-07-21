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
      setState(() => _loading = false);
      return;
    }
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
            SizedBox(
              height: 200,
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
