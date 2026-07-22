import 'package:dio/dio.dart';
import 'package:dts_customer/features/cart/domain/entities/cart.dart';
import 'package:dts_customer/features/cart/infrastructure/datasources/cart_remote_datasource.dart';

/// Fake remoto sin red para tests de CartNotifier.
class FakeCartRemoteDataSource extends CartRemoteDataSource {
  FakeCartRemoteDataSource({this.seed}) : super(Dio());

  Cart? seed;
  final List<String> calls = [];

  @override
  Future<Cart?> getCart() async {
    calls.add('get');
    return seed;
  }

  @override
  Future<Cart?> upsertItem({
    required int productId,
    required int quantity,
    String? notes,
    bool replaceStore = true,
  }) async {
    calls.add('upsert:$productId:$quantity');
    return seed;
  }

  @override
  Future<Cart?> setQuantity({
    required int productId,
    required int quantity,
  }) async {
    calls.add('qty:$productId:$quantity');
    return seed;
  }

  @override
  Future<Cart?> removeItem(int productId) async {
    calls.add('remove:$productId');
    return seed;
  }

  @override
  Future<void> clearCart() async {
    calls.add('clear');
    seed = null;
  }
}
