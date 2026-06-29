import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/cart/application/providers/cart_providers.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:dts_customer/features/catalog/presentation/screens/product_detail_screen.dart';

import '../../../helpers/test_providers.dart';

void main() {
  const product = Product(
    id: 5,
    name: 'Hamburguesa',
    price: 12,
    storeId: 1,
    productType: ProductType.physical,
  );

  testWidgets('add_to_cart_from_catalog_test', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        child: const MaterialApp(
          home: ProductDetailScreen(
            storeId: 1,
            storeName: 'Burger',
            product: product,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('add_to_cart_button')));
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(ProductDetailScreen));
    final container = ProviderScope.containerOf(element);
    final cart = container.read(cartNotifierProvider);

    expect(cart, isNotNull);
    expect(cart!.items, hasLength(1));
    expect(cart.items.first.product.name, 'Hamburguesa');
    expect(cart.total, 12);
  });
}
