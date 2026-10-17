import '../entities/fare_quote.dart';
import '../entities/ride_request.dart';
import '../repositories/rides_repository.dart';

class QuoteRideUseCase {
  const QuoteRideUseCase(this._repository);

  final RidesRepository _repository;

  Future<FareQuote> call(QuoteRideParams params) =>
      _repository.quoteRide(params);
}
