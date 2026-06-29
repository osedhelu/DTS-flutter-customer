import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cart.dart';
import '../../domain/usecases/add_item_usecase.dart';
import '../../../catalog/domain/entities/product.dart';

class CartNotifier extends StateNotifier<Cart?> {
  CartNotifier(this._addItemUseCase) : super(null);

  final AddItemUseCase _addItemUseCase;

  void addProduct({
    required int storeId,
    required String storeName,
    required Product product,
    int quantity = 1,
  }) {
    state = _addItemUseCase.call(
      currentCart: state,
      params: AddItemParams(
        storeId: storeId,
        storeName: storeName,
        product: product,
        quantity: quantity,
      ),
    );
  }

  void clear() => state = null;
}

final addItemUseCaseProvider = Provider<AddItemUseCase>((ref) {
  return AddItemUseCase();
});

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, Cart?>((ref) {
  return CartNotifier(ref.watch(addItemUseCaseProvider));
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider)?.itemCount ?? 0;
});
