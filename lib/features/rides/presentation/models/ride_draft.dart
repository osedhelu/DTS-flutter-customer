import '../../domain/entities/ride_location.dart';

/// Borrador de viaje que se pasa de la pantalla principal a la cotización
/// (`context.push('/rides/quote', extra: RideDraft(...))`).
class RideDraft {
  const RideDraft({required this.pickup, required this.dropoff});

  final RideLocation pickup;
  final RideLocation dropoff;

  bool get isValid => pickup.isValid && dropoff.isValid;
}
