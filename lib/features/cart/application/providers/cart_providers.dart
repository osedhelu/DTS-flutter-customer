import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../domain/entities/cart.dart';
import '../../domain/usecases/add_item_usecase.dart';
import '../../infrastructure/datasources/cart_remote_datasource.dart';

class CartNotifier extends StateNotifier<Cart?> {
  CartNotifier(this._addItemUseCase, this._remote) : super(null);

  final AddItemUseCase _addItemUseCase;
  final CartRemoteDataSource _remote;
  bool _hydrating = false;

  /// Carga carrito del servidor tras login.
  /// Regla: si servidor tiene ítems → usar servidor;
  /// si servidor vacío y hay carrito local → push local.
  Future<void> hydrate() async {
    if (_hydrating) return;
    _hydrating = true;
    final local = state;
    try {
      final remote = await _remote.getCart();
      if (remote != null && !remote.isEmpty) {
        state = remote;
        return;
      }
      if (local != null && !local.isEmpty) {
        await _pushLocal(local);
        return;
      }
      state = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Cart hydrate failed: $e');
    } finally {
      _hydrating = false;
    }
  }

  Future<void> _pushLocal(Cart local) async {
    try {
      await _remote.clearCart();
      Cart? last;
      for (final item in local.items) {
        last = await _remote.upsertItem(
          productId: item.product.id,
          quantity: item.quantity,
          notes: item.notes,
          replaceStore: true,
        );
      }
      state = last ?? local;
    } catch (e) {
      if (kDebugMode) debugPrint('Cart push local failed: $e');
      state = local;
    }
  }

  void addProduct({
    required int storeId,
    required String storeName,
    required Product product,
    int quantity = 1,
    String? notes,
  }) {
    final previous = state;
    try {
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
    } catch (_) {
      // Otro comercio: reemplazar carrito local (alineado con replace_store).
      state = _addItemUseCase.call(
        currentCart: null,
        params: AddItemParams(
          storeId: storeId,
          storeName: storeName,
          product: product,
          quantity: quantity,
          notes: notes,
        ),
      );
    }
    final next = state;
    if (next == null) return;
    final line = next.items.firstWhere((i) => i.product.id == product.id);
    _syncUpsert(line.product.id, line.quantity, line.notes, previous);
  }

  void setQuantity(int productId, int quantity) {
    final cart = state;
    if (cart == null) return;
    final previous = cart;
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final items = cart.items.map((item) {
      if (item.product.id != productId) return item;
      return item.copyWith(quantity: quantity);
    }).toList();
    state = cart.copyWith(items: items);
    _syncSetQuantity(productId, quantity, previous);
  }

  void removeProduct(int productId) {
    final cart = state;
    if (cart == null) return;
    final previous = cart;
    final items =
        cart.items.where((item) => item.product.id != productId).toList();
    state = items.isEmpty ? null : cart.copyWith(items: items);
    _syncRemove(productId, previous);
  }

  void clear() {
    final previous = state;
    state = null;
    _syncClear(previous);
  }

  Future<void> _syncUpsert(
    int productId,
    int quantity,
    String? notes,
    Cart? previous,
  ) async {
    try {
      final remote = await _remote.upsertItem(
        productId: productId,
        quantity: quantity,
        notes: notes,
        replaceStore: true,
      );
      if (remote != null) state = remote;
    } catch (e) {
      if (kDebugMode) debugPrint('Cart upsert sync failed: $e');
      state = previous;
    }
  }

  Future<void> _syncSetQuantity(
    int productId,
    int quantity,
    Cart previous,
  ) async {
    try {
      final remote = await _remote.setQuantity(
        productId: productId,
        quantity: quantity,
      );
      state = remote;
    } catch (e) {
      if (kDebugMode) debugPrint('Cart qty sync failed: $e');
      state = previous;
    }
  }

  Future<void> _syncRemove(int productId, Cart previous) async {
    try {
      final remote = await _remote.removeItem(productId);
      state = remote;
    } catch (e) {
      if (kDebugMode) debugPrint('Cart remove sync failed: $e');
      state = previous;
    }
  }

  Future<void> _syncClear(Cart? previous) async {
    try {
      await _remote.clearCart();
    } catch (e) {
      if (kDebugMode) debugPrint('Cart clear sync failed: $e');
      state = previous;
    }
  }
}

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  return CartRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final addItemUseCaseProvider = Provider<AddItemUseCase>((ref) {
  return const AddItemUseCase();
});

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, Cart?>((ref) {
  return CartNotifier(
    ref.watch(addItemUseCaseProvider),
    ref.watch(cartRemoteDataSourceProvider),
  );
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider)?.itemCount ?? 0;
});
