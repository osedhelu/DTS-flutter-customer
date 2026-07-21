import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/catalog/application/providers/catalog_providers.dart';
import 'package:dts_customer/features/catalog/domain/entities/category.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:dts_customer/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:dts_customer/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late MockCatalogRepository catalogRepository;

  setUp(() {
    catalogRepository = MockCatalogRepository();
  });

  testWidgets('catalog_filter_by_category_test', (tester) async {
    when(() => catalogRepository.getCategoriesByStore(1)).thenAnswer(
      (_) async => const [
        ProductCategory(
          id: 3,
          name: 'Bebidas',
          subcategories: [
            ProductSubcategory(id: 7, name: 'Calientes', parentId: 3),
          ],
        ),
      ],
    );
    when(
      () => catalogRepository.getProductsByStore(
        1,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => const [
        Product(
          id: 1,
          name: 'Café',
          price: 3,
          storeId: 1,
          productType: ProductType.physical,
          categoryId: 3,
        ),
        Product(
          id: 2,
          name: 'Masaje',
          price: 40,
          storeId: 1,
          productType: ProductType.service,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(catalogRepository),
        ],
        child: const MaterialApp(
          home: CatalogScreen(storeId: 1, storeName: 'Spa'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Café'), findsOneWidget);
    expect(find.text('Masaje'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter_service')));
    await tester.pumpAndSettle();

    verify(
      () => catalogRepository.getProductsByStore(
        1,
        filters: any(
          named: 'filters',
          that: predicate<ProductFilters>(
            (f) => f.productType == ProductType.service,
          ),
        ),
      ),
    ).called(greaterThan(0));
  });
}
