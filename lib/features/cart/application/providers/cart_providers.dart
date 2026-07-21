import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalog/domain/entities/product.dart';
import '../../domain/entities/cart.dart';
import '../../domain/usecases/add_item_usecase.dart';

class CartNotifier extends StateNotifier<Cart?> {
  CartNotifier(this._addItemUseCase) : super(null);

  final AddItemUseCase _addItemUseCase;

  void addProduct({
    required int storeId,
    required String storeName,
    required Product product,
    int quantity = 1,
    String? notes,
  }) {
    state = _addItemUseCase.call(
      currentCart: state,
      params: AddItemParams(
        storeId: storeId,
        storeName: storeName,
        product: product,
        quantity: quantity,
        notes: notes,
      ),
    );
  }

  void setQuantity(int productId, int quantity) {
    final cart = state;
    if (cart == null) return;
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final items = cart.items.map((item) {
      if (item.product.id != productId) return item;
      return item.copyWith(quantity: quantity);
    }).toList();
    state = cart.copyWith(items: items);
  }

  void removeProduct(int productId) {
    final cart = state;
    if (cart == null) return;
    final items =
        cart.items.where((item) => item.product.id != productId).toList();
    state = items.isEmpty ? null : cart.copyWith(items: items);
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
