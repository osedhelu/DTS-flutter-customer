import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/infrastructure/datasources/auth_remote_datasource.dart';
import '../../features/auth/infrastructure/repositories/auth_repository_impl.dart';
import '../../features/catalog/domain/repositories/catalog_repository.dart';
import '../../features/catalog/infrastructure/datasources/catalog_remote_datasource.dart';
import '../../features/catalog/infrastructure/repositories/catalog_repository_impl.dart';
import '../../features/checkout/domain/repositories/orders_repository.dart';
import '../../features/checkout/infrastructure/datasources/orders_remote_datasource.dart';
import '../../features/checkout/infrastructure/repositories/orders_repository_impl.dart';
import '../../features/notifications/domain/repositories/device_token_repository.dart';
import '../../features/notifications/infrastructure/datasources/device_token_remote_datasource.dart';
import '../../features/notifications/infrastructure/repositories/device_token_repository_impl.dart';
import '../../features/stores/domain/repositories/stores_repository.dart';
import '../../features/stores/infrastructure/datasources/stores_remote_datasource.dart';
import '../../features/stores/infrastructure/repositories/stores_repository_impl.dart';
import '../../features/tracking/domain/repositories/tracking_repository.dart';
import '../../features/tracking/infrastructure/datasources/tracking_remote_datasource.dart';
import '../../features/tracking/infrastructure/datasources/tracking_ws_datasource.dart';
import '../../features/tracking/infrastructure/repositories/tracking_repository_impl.dart';
import '../network/api_client.dart';
import '../network/token_storage.dart';
import '../../firebase_options.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: const ['email'],
    clientId: Platform.isIOS ? DefaultFirebaseOptions.ios.iosClientId : null,
    serverClientId: DefaultFirebaseOptions.googleServerClientId,
  );
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: storage);
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    googleSignIn: ref.watch(googleSignInProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

final storesRemoteDataSourceProvider = Provider<StoresRemoteDataSource>((ref) {
  return StoresRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final storesRepositoryProvider = Provider<StoresRepository>((ref) {
  return StoresRepositoryImpl(
    remoteDataSource: ref.watch(storesRemoteDataSourceProvider),
  );
});

final catalogRemoteDataSourceProvider = Provider<CatalogRemoteDataSource>((ref) {
  return CatalogRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(
    remoteDataSource: ref.watch(catalogRemoteDataSourceProvider),
  );
});

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>((ref) {
  return OrdersRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
  );
});

final trackingRemoteDataSourceProvider =
    Provider<TrackingRemoteDataSource>((ref) {
  return TrackingRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final trackingWsDataSourceProvider = Provider<TrackingWsDataSource>((ref) {
  final datasource = TrackingWsDataSource();
  ref.onDispose(() {
    datasource.disconnect();
  });
  return datasource;
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepositoryImpl(
    remoteDataSource: ref.watch(trackingRemoteDataSourceProvider),
  );
});

final deviceTokenRemoteDataSourceProvider =
    Provider<DeviceTokenRemoteDataSource>((ref) {
  return DeviceTokenRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepositoryImpl(
    remoteDataSource: ref.watch(deviceTokenRemoteDataSourceProvider),
  );
});
