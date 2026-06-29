import 'package:flutter_test/flutter_test.dart';

import 'package:dts_customer/features/cart/domain/entities/cart.dart';
import 'package:dts_customer/features/cart/domain/usecases/add_item_usecase.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';

void main() {
  const product = Product(
    id: 1,
    name: 'Café',
    price: 3.5,
    storeId: 10,
    productType: ProductType.physical,
  );

  const useCase = AddItemUseCase();

  test('cart_add_item_test', () {
    final cart = useCase.call(
      params: const AddItemParams(
        storeId: 10,
        storeName: 'Café',
        product: product,
      ),
    );

    expect(cart.items, hasLength(1));
    expect(cart.items.first.quantity, 1);
  });

  test('cart_total_test', () {
    final first = useCase.call(
      params: const AddItemParams(
        storeId: 10,
        storeName: 'Café',
        product: product,
        quantity: 2,
      ),
    );
    const other = Product(
      id: 2,
      name: 'Té',
      price: 2,
      storeId: 10,
      productType: ProductType.physical,
    );
    final cart = useCase.call(
      currentCart: first,
      params: const AddItemParams(
        storeId: 10,
        storeName: 'Café',
        product: other,
        quantity: 1,
      ),
    );

    expect(cart.total, 9);
    expect(cart.itemCount, 3);
  });
}
