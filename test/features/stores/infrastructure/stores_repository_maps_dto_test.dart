import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_customer/features/stores/infrastructure/datasources/stores_remote_datasource.dart';
import 'package:dts_customer/features/stores/infrastructure/repositories/stores_repository_impl.dart';

class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response<dynamic> {}

void main() {
  late MockDio dio;
  late StoresRepositoryImpl repository;

  setUp(() {
    dio = MockDio();
    repository = StoresRepositoryImpl(
      remoteDataSource: StoresRemoteDataSource(dio),
    );
  });

  test('stores_repository_maps_dto_test paginated', () async {
    final response = MockResponse();
    when(() => response.data).thenReturn({
      'results': [
        {
          'id': 1,
          'name': 'Café Central',
          'logo_url': 'https://cdn.example/logo.png',
          'is_open': true,
        },
      ],
    });
    when(() => dio.get<dynamic>('/stores/')).thenAnswer((_) async => response);

    final stores = await repository.getStores();

    expect(stores, hasLength(1));
    expect(stores.first.id, 1);
    expect(stores.first.name, 'Café Central');
    expect(stores.first.logoUrl, 'https://cdn.example/logo.png');
    expect(stores.first.isOpen, isTrue);
  });

  test('stores_repository_maps_dto_test list', () async {
    final response = MockResponse();
    when(() => response.data).thenReturn([
      {'id': 2, 'name': 'Tienda Lista', 'is_open': false},
    ]);
    when(() => dio.get<dynamic>('/stores/')).thenAnswer((_) async => response);

    final stores = await repository.getStores();

    expect(stores.first.id, 2);
    expect(stores.first.isOpen, isFalse);
  });
}
