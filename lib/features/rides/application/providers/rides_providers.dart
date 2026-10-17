import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/ride.dart';
import '../../domain/usecases/cancel_ride_usecase.dart';
import '../../domain/usecases/create_ride_usecase.dart';
import '../../domain/usecases/get_ride_usecase.dart';
import '../../domain/usecases/list_rides_usecase.dart';
import '../../domain/usecases/quote_ride_usecase.dart';
import '../../domain/usecases/watch_ride_usecase.dart';

final quoteRideUseCaseProvider = Provider<QuoteRideUseCase>((ref) {
  return QuoteRideUseCase(ref.watch(ridesRepositoryProvider));
});

final createRideUseCaseProvider = Provider<CreateRideUseCase>((ref) {
  return CreateRideUseCase(ref.watch(ridesRepositoryProvider));
});

final cancelRideUseCaseProvider = Provider<CancelRideUseCase>((ref) {
  return CancelRideUseCase(ref.watch(ridesRepositoryProvider));
});

final getRideUseCaseProvider = Provider<GetRideUseCase>((ref) {
  return GetRideUseCase(ref.watch(ridesRepositoryProvider));
});

final listRidesUseCaseProvider = Provider<ListRidesUseCase>((ref) {
  return ListRidesUseCase(ref.watch(ridesRepositoryProvider));
});

final watchRideUseCaseProvider = Provider<WatchRideUseCase>((ref) {
  return WatchRideUseCase(ref.watch(ridesRepositoryProvider));
});

/// Historial de viajes del cliente (se refresca al invalidar).
final rideHistoryProvider = FutureProvider<List<Ride>>((ref) async {
  return ref.watch(listRidesUseCaseProvider).call();
});
