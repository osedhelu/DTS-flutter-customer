import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/usecases/apple_sign_in_usecase.dart';
import '../../features/auth/domain/usecases/google_sign_in_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/checkout/domain/usecases/create_order_usecase.dart';
import '../../features/checkout/domain/usecases/create_service_order_usecase.dart';
import '../../features/notifications/application/push_notification_handler.dart';
import '../../features/notifications/domain/usecases/register_fcm_token_usecase.dart';
import '../../features/tracking/domain/usecases/get_tracking_usecase.dart';
import '../../features/profile/infrastructure/datasources/customer_profile_remote_datasource.dart';
import '../../core/firebase/firebase_service.dart';
import 'repository_providers.dart';

export '../../features/cart/application/providers/cart_providers.dart';
export '../../features/catalog/application/providers/catalog_providers.dart';
export '../../features/stores/application/providers/stores_providers.dart';
export 'repository_providers.dart';

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final googleSignInUseCaseProvider = Provider<GoogleSignInUseCase>((ref) {
  return GoogleSignInUseCase(ref.watch(authRepositoryProvider));
});

final appleSignInUseCaseProvider = Provider<AppleSignInUseCase>((ref) {
  return AppleSignInUseCase(ref.watch(authRepositoryProvider));
});

final authStateProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authRepositoryProvider).isAuthenticated();
});

final createOrderUseCaseProvider = Provider<CreateOrderUseCase>((ref) {
  return CreateOrderUseCase(ref.watch(ordersRepositoryProvider));
});

final createServiceOrderUseCaseProvider =
    Provider<CreateServiceOrderUseCase>((ref) {
  return CreateServiceOrderUseCase(ref.watch(ordersRepositoryProvider));
});

final getTrackingUseCaseProvider = Provider<GetTrackingUseCase>((ref) {
  return GetTrackingUseCase(ref.watch(trackingRepositoryProvider));
});

final registerFcmTokenUseCaseProvider = Provider<RegisterFcmTokenUseCase>((ref) {
  return RegisterFcmTokenUseCase(ref.watch(deviceTokenRepositoryProvider));
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseServiceImpl();
});

final pushNotificationHandlerProvider = Provider<PushNotificationHandler>((ref) {
  final handler = PushNotificationHandler(
    firebaseService: ref.watch(firebaseServiceProvider),
  );
  ref.onDispose(handler.dispose);
  return handler;
});

final customerProfileRemoteDataSourceProvider =
    Provider<CustomerProfileRemoteDataSource>((ref) {
  return CustomerProfileRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final connectivityOfflineProvider = StateProvider<bool>((ref) => false);
