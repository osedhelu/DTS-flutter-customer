import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/product_detail_screen.dart';
import '../../features/catalog/presentation/screens/service_detail_screen.dart';
import '../../features/chat/presentation/screens/order_chat_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/service_checkout_screen.dart';
import '../../features/checkout/presentation/screens/service_order_tracking_screen.dart';
import '../../features/orders/presentation/screens/customer_order_detail_screen.dart';
import '../../features/profile/presentation/screens/addresses_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/help_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/stores/presentation/screens/store_detail_screen.dart';
import '../../features/shell/presentation/screens/customer_shell_screen.dart';
import '../../features/tracking/presentation/screens/tracking_map_screen.dart';
import '../di/providers.dart';

class AuthRouterListenable extends ChangeNotifier {
  AuthRouterListenable(this._ref) {
    _ref.listen<AsyncValue<bool>>(authStateProvider, (prev, next) {
      if (next.isLoading) return;
      final prevAuth = prev?.asData?.value;
      final nextAuth = next.asData?.value;
      if (prev != null &&
          prev.hasValue &&
          next.hasValue &&
          prevAuth == nextAuth) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
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
  ref.keepAlive();

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final isAuthGate = loc == '/splash';
      final isPublic = isAuthGate ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password';

      if (!auth.hasValue && !auth.hasError) {
        return isAuthGate ? null : '/splash';
      }
      if (auth.hasError) {
        return loc == '/login' ? null : '/login';
      }

      final isAuthenticated = auth.requireValue;
      if (isAuthGate) {
        return isAuthenticated ? '/home' : '/login';
      }
      if (!isAuthenticated && !isPublic) return '/login';
      if (isAuthenticated &&
          (loc == '/login' ||
              loc == '/register' ||
              loc == '/forgot-password')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CustomerShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const ShellHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const ShellOrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['orderId']!);
                      return CustomerOrderDetailScreen(orderId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'chat',
                        builder: (context, state) {
                          final id =
                              int.parse(state.pathParameters['orderId']!);
                          return OrderChatScreen(orderId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const ShellCartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ShellProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/stores',
        redirect: (_, __) => '/home',
      ),
      GoRoute(
        path: '/stores/:storeId',
        builder: (context, state) {
          final storeId = int.parse(state.pathParameters['storeId']!);
          return StoreDetailScreen(storeId: storeId);
        },
      ),
      GoRoute(
        path: '/stores/:storeId/catalog',
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
              final productId = int.parse(state.pathParameters['productId']!);
              final storeName =
                  state.extra as String? ??
                  state.uri.queryParameters['name'] ??
                  'Comercio';
              return ProductDetailScreen(
                storeId: storeId,
                storeName: storeName,
                productId: productId,
              );
            },
          ),
          GoRoute(
            path: 'services/:productId',
            builder: (context, state) {
              final storeId = int.parse(state.pathParameters['storeId']!);
              final productId = int.parse(state.pathParameters['productId']!);
              final storeName =
                  state.extra as String? ??
                  state.uri.queryParameters['name'] ??
                  'Comercio';
              return ServiceDetailScreen(
                storeId: storeId,
                storeName: storeName,
                productId: productId,
              );
            },
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
        path: '/addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/tracking/:orderId',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          return TrackingMapScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/service-tracking/:orderId',
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          return ServiceOrderTrackingScreen(orderId: orderId);
        },
      ),
    ],
  );
});
