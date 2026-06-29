import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/catalog/domain/entities/product.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/product_detail_screen.dart';
import '../../features/catalog/presentation/screens/service_detail_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/service_checkout_screen.dart';
import '../../features/checkout/presentation/screens/service_order_tracking_screen.dart';
import '../../features/stores/presentation/screens/store_list_screen.dart';
import '../../features/tracking/presentation/screens/tracking_map_screen.dart';
import '../di/providers.dart';

class AuthRouterListenable extends ChangeNotifier {
  AuthRouterListenable(this._ref) {
    _ref.listen<AsyncValue<bool>>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

final authRouterListenableProvider = Provider<AuthRouterListenable>((ref) {
  final listenable = AuthRouterListenable(ref);
  ref.onDispose(listenable.dispose);
  return listenable;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(authRouterListenableProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final isLogin = state.matchedLocation == '/login';
      final isRegister = state.matchedLocation == '/register';
      final isAuthRoute = isLogin || isRegister;

      return auth.when(
        data: (isAuthenticated) {
          if (!isAuthenticated && !isAuthRoute) return '/login';
          if (isAuthenticated && isAuthRoute) return '/stores';
          return null;
        },
        loading: () => isAuthRoute ? null : null,
        error: (_, __) => '/login',
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/stores',
        builder: (context, state) => const StoreListScreen(),
        routes: [
          GoRoute(
            path: ':storeId/catalog',
            builder: (context, state) {
              final storeId = int.parse(state.pathParameters['storeId']!);
              final storeName = state.uri.queryParameters['name'];
              return CatalogScreen(storeId: storeId, storeName: storeName);
            },
            routes: [
              GoRoute(
                path: 'products/:productId',
                builder: (context, state) {
                  final storeId = int.parse(state.pathParameters['storeId']!);
                  final product = state.extra as Product;
                  final storeName =
                      state.uri.queryParameters['name'] ?? 'Comercio';
                  return ProductDetailScreen(
                    storeId: storeId,
                    storeName: storeName,
                    product: product,
                  );
                },
              ),
              GoRoute(
                path: 'services/:productId',
                builder: (context, state) {
                  final storeId = int.parse(state.pathParameters['storeId']!);
                  final product = state.extra as Product;
                  final storeName =
                      state.uri.queryParameters['name'] ?? 'Comercio';
                  return ServiceDetailScreen(
                    storeId: storeId,
                    storeName: storeName,
                    product: product,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
        routes: [
          GoRoute(
            path: 'service',
            builder: (context, state) => const ServiceCheckoutScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/orders/:orderId/tracking',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          return TrackingMapScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:orderId/service-tracking',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          return ServiceOrderTrackingScreen(orderId: orderId);
        },
      ),
    ],
  );
});
