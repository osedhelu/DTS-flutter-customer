import 'package:flutter_test/flutter_test.dart';

import 'package:dts_customer/features/cart/domain/usecases/add_item_usecase.dart';
import 'package:dts_customer/features/catalog/domain/entities/product.dart';

void main() {
  const useCase = AddItemUseCase();
  const product = Product(
    id: 1,
    name: 'Combo',
    price: 10,
    storeId: 3,
    productType: ProductType.physical,
  );

  test('cart_total_test', () {
    final cart = useCase.call(
      params: const AddItemParams(
        storeId: 3,
        storeName: 'Resto',
        product: product,
        quantity: 3,
      ),
    );

    expect(cart.total, 30);
  });
}
