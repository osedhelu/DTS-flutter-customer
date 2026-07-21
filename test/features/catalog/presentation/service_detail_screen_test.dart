import 'package:dts_customer/features/catalog/application/providers/catalog_providers.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:dts_customer/features/catalog/domain/entities/product_detail.dart';
import 'package:dts_customer/features/catalog/presentation/screens/service_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_providers.dart';

void main() {
  const service = Product(
    id: 9,
    name: 'Masaje relajante',
    price: 50,
    storeId: 2,
    productType: ProductType.service,
    description: 'Sesión de 60 minutos',
    durationMinutes: 60,
  );

  testWidgets('service_detail_screen_test', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          productDetailProvider((storeId: 2, productId: 9)).overrideWith(
            (ref) async => const ProductDetail(product: service),
          ),
        ],
        child: const MaterialApp(
          home: ServiceDetailScreen(
            storeId: 2,
            storeName: 'Spa',
            productId: 9,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Masaje relajante'), findsWidgets);
    expect(find.text('Duración estimada: 60 min'), findsOneWidget);
    expect(find.text('Sesión de 60 minutos'), findsOneWidget);
    expect(find.byKey(const Key('request_service_button')), findsOneWidget);
  });
}
