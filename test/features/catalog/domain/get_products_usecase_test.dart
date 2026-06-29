import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:dts_customer/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:dts_customer/features/catalog/domain/usecases/get_products_by_store_usecase.dart';

class MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late MockCatalogRepository repository;
  late GetProductsByStoreUseCase useCase;

  setUp(() {
    repository = MockCatalogRepository();
    useCase = GetProductsByStoreUseCase(repository);
  });

  test('get_products_usecase_test', () async {
    const products = [
      Product(
        id: 10,
        name: 'Latte',
        price: 4.5,
        storeId: 1,
        productType: ProductType.physical,
      ),
    ];

    when(
      () => repository.getProductsByStore(
        1,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => products);

    final result = await useCase(
      storeId: 1,
      filters: const ProductFilters(productType: ProductType.physical),
    );

    expect(result, products);
    verify(
      () => repository.getProductsByStore(
        1,
        filters: const ProductFilters(productType: ProductType.physical),
      ),
    ).called(1);
  });
}
