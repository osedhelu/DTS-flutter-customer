import '../entities/fare_quote.dart';
import '../entities/ride.dart';
import '../entities/ride_request.dart';
import '../entities/ride_tracking_update.dart';

abstract class RidesRepository {
  /// Cotiza un viaje (tarifa + distancia/tiempo estimados) antes de pedirlo.
  Future<FareQuote> quoteRide(QuoteRideParams params);

  /// Solicita un viaje y lo deja buscando conductor.
  Future<Ride> createRide(CreateRideParams params);

  /// Obtiene un viaje por id (estado actual + datos).
  Future<Ride> getRide(int rideId);

  /// Historial de viajes del cliente.
  Future<List<Ride>> listRides();

  /// Cancela un viaje (solo antes del pickup).
  Future<Ride> cancelRide(int rideId);

  /// Stream en vivo del conductor/estado del viaje (WebSocket).
  Stream<RideTrackingUpdate> watchRide(int rideId);
}
