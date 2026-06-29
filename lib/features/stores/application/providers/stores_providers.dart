import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/entities/store.dart';
import '../../domain/usecases/get_stores_usecase.dart';

final getStoresUseCaseProvider = Provider<GetStoresUseCase>((ref) {
  return GetStoresUseCase(ref.watch(storesRepositoryProvider));
});

final storesListProvider = FutureProvider<List<Store>>((ref) {
  return ref.watch(getStoresUseCaseProvider).call();
});
