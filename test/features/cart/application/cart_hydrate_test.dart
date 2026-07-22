import 'package:dts_customer/features/cart/application/providers/cart_providers.dart';
import 'package:dts_customer/features/cart/domain/entities/cart.dart';
import 'package:dts_customer/features/cart/domain/usecases/add_item_usecase.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_cart_remote.dart';

void main() {
  test('hydrate restaura ítems del servidor', () async {
    final remote = FakeCartRemoteDataSource(
      seed: const Cart(
        storeId: 1,
        storeName: 'Server Store',
        items: [
          CartItem(
            product: Product(
              id: 9,
              name: 'Server Item',
              price: 5,
              storeId: 1,
              productType: ProductType.physical,
            ),
            quantity: 2,
          ),
        ],
      ),
    );

    final notifier = CartNotifier(const AddItemUseCase(), remote);
    await notifier.hydrate();

    expect(notifier.state?.storeName, 'Server Store');
    expect(notifier.state?.items.single.product.id, 9);
    expect(notifier.state?.itemCount, 2);
    expect(remote.calls, contains('get'));
  });

  test('addProduct dispara upsert remoto con cantidad absoluta', () async {
    final remote = FakeCartRemoteDataSource();
    final notifier = CartNotifier(const AddItemUseCase(), remote);

    notifier.addProduct(
      storeId: 1,
      storeName: 'Café',
      product: const Product(
        id: 3,
        name: 'Latte',
        price: 12,
        storeId: 1,
        productType: ProductType.physical,
      ),
      quantity: 2,
    );

    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(remote.calls.any((c) => c.startsWith('upsert:3:2')), isTrue);
    expect(notifier.state?.itemCount, 2);
  });
}
