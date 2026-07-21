import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Reproduce Navigator keyReservation / Future already completed with the
/// same shell topology as the customer app (4-branch indexedStack + siblings).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ValueNotifier<AsyncValue<bool>> auth;

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final a = auth.value;
        final loc = state.matchedLocation;
        if (!a.hasValue && !a.hasError) {
          return loc == '/splash' ? null : '/splash';
        }
        if (a.hasError) return '/login';
        final ok = a.requireValue;
        if (loc == '/splash') return ok ? '/home' : '/login';
        if (!ok && loc != '/login') return '/login';
        if (ok && loc == '/login') return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const Scaffold(body: Text('splash')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('login')),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return Scaffold(
              body: navigationShell,
              bottomNavigationBar: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: navigationShell.goBranch,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home), label: 'H'),
                  NavigationDestination(icon: Icon(Icons.list), label: 'O'),
                  NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'C'),
                  NavigationDestination(icon: Icon(Icons.person), label: 'P'),
                ],
              ),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const Text('home'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/orders',
                  builder: (_, __) => const Text('orders'),
                  routes: [
                    GoRoute(
                      path: ':orderId',
                      builder: (_, __) => const Text('order-detail'),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  builder: (_, __) => const Text('cart'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, __) => const Text('profile'),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/stores/:storeId',
          builder: (_, __) => const Text('store'),
        ),
        GoRoute(
          path: '/tracking/:orderId',
          builder: (_, __) => const Text('tracking'),
        ),
      ],
    );
  }

  testWidgets('splash→home auth redirect does not crash Navigator',
      (tester) async {
    auth = ValueNotifier<AsyncValue<bool>>(const AsyncLoading());
    final router = buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          builder: (context, child) => Stack(
            children: [child ?? const SizedBox.shrink()],
          ),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('splash'), findsOneWidget);

    auth.value = const AsyncData(true);
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Column+Expanded builder + auth redirect', (tester) async {
    auth = ValueNotifier<AsyncValue<bool>>(const AsyncLoading());
    final router = buildRouter();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          builder: (context, child) => Column(
            children: [
              const SizedBox.shrink(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    auth.value = const AsyncData(true);
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy /orders/:id/tracking path still matches without assert',
      (tester) async {
    // En go_router 14 este conflicto ya no siempre asserta en test;
    // se mantiene /tracking/:id en producción por claridad de rutas.
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return Scaffold(body: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const Text('home'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/orders',
                  builder: (_, __) => const Text('orders'),
                  routes: [
                    GoRoute(
                      path: ':orderId',
                      builder: (_, state) =>
                          Text('detail-${state.pathParameters['orderId']}'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/orders/:orderId/tracking',
          builder: (_, __) => const Text('tracking'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.go('/orders/42/tracking');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('FIXED paths /tracking/:id do not collide with shell orders',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return Scaffold(body: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const Text('home'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/orders',
                  builder: (_, __) => const Text('orders'),
                  routes: [
                    GoRoute(
                      path: ':orderId',
                      builder: (_, __) => const Text('detail'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/tracking/:orderId',
          builder: (_, __) => const Text('tracking'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.go('/tracking/42');
    await tester.pumpAndSettle();
    expect(find.text('tracking'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
