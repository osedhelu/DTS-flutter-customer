import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/polyline_decoder.dart';

/// Constructor del widget de mapa de viajes.
///
/// Se inyecta vía provider para poder sustituir GoogleMap en tests de widgets
/// (mismo patrón que `mapWidgetBuilderProvider` del tracking).
/// El parámetro `routePoints` (opcional) trae la ruta real sobre calles
/// decodificada para pintar la Polyline y encuadrar la cámara.
typedef RidesMapBuilder = Widget Function({
  required LatLng? pickupPosition,
  required LatLng? dropoffPosition,
  required LatLng? driverPosition,
  ValueChanged<LatLng>? onMapTap,
  List<LatLng>? routePoints,
});

const LatLng defaultRideCenter = LatLng(4.7110, -74.0721);

/// Margen en píxeles de la cámara al encuadrar la ruta (deja sitio a la
/// tarjeta de estado y a los botones flotantes del tracking).
const double _routeCameraPadding = 90;

/// Marcadores diferenciados por rol:
/// - Origen → pin verde (punto de partida).
/// - Destino → pin rojo (llegada).
/// - Conductor → pin azul (solo tracking).
///
/// Se omite el `InfoWindow` de origen/destino para evitar la etiqueta
/// flotante genérica ("Destino") que se empalma con los marcadores.
Set<Marker> buildRideMarkers({
  required LatLng? pickupPosition,
  required LatLng? dropoffPosition,
  required LatLng? driverPosition,
}) {
  final markers = <Marker>{};
  if (pickupPosition != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('ride_pickup'),
        position: pickupPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      ),
    );
  }
  if (dropoffPosition != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('ride_dropoff'),
        position: dropoffPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }
  if (driverPosition != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('ride_driver'),
        position: driverPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: const InfoWindow(title: 'Conductor'),
      ),
    );
  }
  return markers;
}

/// Polilínea Origen → Destino.
///
/// Si se recibe la ruta real sobre calles decodificada (`routePoints`), se
/// traza siguiendo la malla vial. De lo contrario (p. ej. antes de cotizar o
/// sin proveedor de rutas configurado) se degrada a la línea recta que unía
/// ambos puntos, manteniendo el comportamiento previo.
Polyline? buildRideRoutePolyline({
  required LatLng? pickupPosition,
  required LatLng? dropoffPosition,
  List<LatLng>? routePoints,
}) {
  if (pickupPosition == null || dropoffPosition == null) return null;

  final points = (routePoints != null && routePoints.length >= 2)
      ? routePoints
      : <LatLng>[pickupPosition, dropoffPosition];

  return Polyline(
    polylineId: const PolylineId('ride_route'),
    points: points,
    color: AppColors.coral,
    width: 4,
  );
}

/// Encuadra el mapa sobre la ruta real usando `CameraUpdate.newLatLngBounds`.
///
/// Wrapper interno del builder: captura el [GoogleMapController] y anima la
/// cámara cuando cambia la geografía de la ruta (puntos sobre calles).
class _RidesFittedMap extends StatefulWidget {
  const _RidesFittedMap({
    required this.markers,
    required this.route,
    required this.onMapTap,
    required this.initial,
  });

  final Set<Marker> markers;
  final Polyline? route;
  final ValueChanged<LatLng>? onMapTap;
  final LatLng initial;

  @override
  State<_RidesFittedMap> createState() => _RidesFittedMapState();
}

class _RidesFittedMapState extends State<_RidesFittedMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant _RidesFittedMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameRoutePoints(oldWidget.route, widget.route)) {
      _fitToRoute();
    }
  }

  /// Compara los puntos de la ruta por valor (no por identidad): evita
  /// re-encuadrar la cámara en cada rebuild (p. ej. updates de WebSocket).
  static bool _sameRoutePoints(Polyline? a, Polyline? b) {
    final pointsA = a?.points ?? const <LatLng>[];
    final pointsB = b?.points ?? const <LatLng>[];
    if (pointsA.length != pointsB.length) return false;
    for (var i = 0; i < pointsA.length; i++) {
      if (pointsA[i] != pointsB[i]) return false;
    }
    return true;
  }

  Future<void> _fitToRoute() async {
    final controller = _controller;
    final points = widget.route?.points ?? const <LatLng>[];
    if (controller == null || points.length < 2) return;

    final bounds = _expandedBounds(boundsOf(points));
    if (bounds == null) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, _routeCameraPadding),
    );
  }

  /// Expande límites degenerados (min == max en un eje) para que
  /// `newLatLngBounds` funcione con rutas muy cortas o rectas.
  static LatLngBounds? _expandedBounds(LatLngBounds? bounds) {
    if (bounds == null) return null;
    const delta = 0.0005;
    final south = bounds.southwest.latitude;
    final north = bounds.northeast.latitude;
    final west = bounds.southwest.longitude;
    final east = bounds.northeast.longitude;
    final southExpanded = (north - south) < delta / 2 ? south - delta : south;
    final northExpanded = (north - south) < delta / 2 ? north + delta : north;
    final westExpanded = (east - west) < delta / 2 ? west - delta : west;
    final eastExpanded = (east - west) < delta / 2 ? east + delta : east;
    return LatLngBounds(
      southwest: LatLng(southExpanded, westExpanded),
      northeast: LatLng(northExpanded, eastExpanded),
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    // Espera el primer layout para que `animateCamera` tenga el tamaño real.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToRoute());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      key: const Key('rides_map'),
      initialCameraPosition: CameraPosition(target: widget.initial, zoom: 14),
      markers: widget.markers,
      polylines: widget.route == null ? const <Polyline>{} : {widget.route!},
      onTap: widget.onMapTap,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: _onMapCreated,
    );
  }
}

final ridesMapBuilderProvider = Provider<RidesMapBuilder>((ref) {
  return ({
    required LatLng? pickupPosition,
    required LatLng? dropoffPosition,
    required LatLng? driverPosition,
    ValueChanged<LatLng>? onMapTap,
    List<LatLng>? routePoints,
  }) {
    final markers = buildRideMarkers(
      pickupPosition: pickupPosition,
      dropoffPosition: dropoffPosition,
      driverPosition: driverPosition,
    );
    final route = buildRideRoutePolyline(
      pickupPosition: pickupPosition,
      dropoffPosition: dropoffPosition,
      routePoints: routePoints,
    );

    final initial = pickupPosition ??
        dropoffPosition ??
        driverPosition ??
        defaultRideCenter;

    return _RidesFittedMap(
      markers: markers,
      route: route,
      onMapTap: onMapTap,
      initial: initial,
    );
  };
});
