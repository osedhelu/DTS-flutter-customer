import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/product.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.product,
    required this.quantity,
    this.notes,
  });

  final Product product;
  final int quantity;
  final String? notes;

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity, String? notes}) => CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props => [product, quantity, notes];
}

class Cart extends Equatable {
  const Cart({
    required this.storeId,
    required this.storeName,
    required this.items,
  });

  final int storeId;
  final String storeName;
  final List<CartItem> items;

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  Cart copyWith({List<CartItem>? items}) => Cart(
        storeId: storeId,
        storeName: storeName,
        items: items ?? this.items,
      );

  @override
  List<Object?> get props => [storeId, storeName, items];
}
