/// Estados de un viaje de pasajeros (rideshare), espejo de `OrderStatus`
/// del backend para los estados del tipo RIDE.
enum RideStatus {
  created('created', 'Pendiente'),
  searchingDriver('searching_driver', 'Buscando conductor'),
  driverAccepted('driver_accepted', 'Conductor asignado'),
  driverEnRouteToPickup('driver_en_route_to_pickup', 'Conductor en camino'),
  driverAtPickup('driver_at_pickup', 'Conductor en el punto'),
  rideInProgress('ride_in_progress', 'En viaje'),
  rideCompleted('ride_completed', 'Viaje completado'),
  cancelled('cancelled', 'Cancelado'),
  unknown('unknown', 'Desconocido');

  const RideStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static RideStatus fromApi(String? value) {
    if (value == null) return RideStatus.unknown;
    final normalized = value.toLowerCase();
    for (final status in RideStatus.values) {
      if (status.apiValue == normalized) return status;
    }
    return RideStatus.unknown;
  }

  /// Un viaje sigue "vivo" (requiere tracking) mientras no sea terminal.
  bool get isActive =>
      this != RideStatus.rideCompleted &&
      this != RideStatus.cancelled &&
      this != RideStatus.unknown;

  bool get isTerminal =>
      this == RideStatus.rideCompleted || this == RideStatus.cancelled;

  /// Solo se puede cancelar antes de recoger al pasajero.
  bool get canCancel =>
      this == RideStatus.created ||
      this == RideStatus.searchingDriver ||
      this == RideStatus.driverAccepted ||
      this == RideStatus.driverEnRouteToPickup;
}
