import '../../../catalog/domain/entities/product.dart';
import '../entities/cart.dart';

class AddItemParams {
  const AddItemParams({
    required this.storeId,
    required this.storeName,
    required this.product,
    this.quantity = 1,
    this.notes,
  });

  final int storeId;
  final String storeName;
  final Product product;
  final int quantity;
  final String? notes;
}

class AddItemUseCase {
  const AddItemUseCase();

  Cart call({Cart? currentCart, required AddItemParams params}) {
    final product = params.product;
    if (currentCart != null && currentCart.storeId != params.storeId) {
      throw StateError('El carrito pertenece a otro comercio');
    }

    final baseCart = currentCart ??
        Cart(
          storeId: params.storeId,
          storeName: params.storeName,
          items: const [],
        );

    final existingIndex = baseCart.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    final updatedItems = List<CartItem>.from(baseCart.items);
    if (existingIndex >= 0) {
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + params.quantity,
        notes: params.notes ?? existing.notes,
      );
    } else {
      updatedItems.add(
        CartItem(
          product: product,
          quantity: params.quantity,
          notes: params.notes,
        ),
      );
    }

    return baseCart.copyWith(items: updatedItems);
  }
}
