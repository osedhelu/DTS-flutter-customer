import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_customer/features/stores/domain/entities/store.dart';
import 'package:dts_customer/features/stores/domain/repositories/stores_repository.dart';
import 'package:dts_customer/features/stores/domain/usecases/get_stores_usecase.dart';

class MockStoresRepository extends Mock implements StoresRepository {}

void main() {
  late MockStoresRepository repository;
  late GetStoresUseCase useCase;

  setUp(() {
    repository = MockStoresRepository();
    useCase = GetStoresUseCase(repository);
  });

  test('get_stores_usecase_test', () async {
    const stores = [
      Store(id: 1, name: 'Café Central'),
      Store(id: 2, name: 'Pizza Norte'),
    ];

    when(() => repository.getStores()).thenAnswer((_) async => stores);

    final result = await useCase();

    expect(result, stores);
    verify(() => repository.getStores()).called(1);
  });
}
