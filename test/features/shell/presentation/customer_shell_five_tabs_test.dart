import 'package:dts_customer/features/cart/application/providers/cart_providers.dart';
import 'package:dts_customer/features/shell/presentation/screens/customer_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/test_providers.dart';

void main() {
  testWidgets('customer_shell_has_five_tabs_test', (tester) async {
    final router = GoRouter(
      initialLocation: '/rides',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              CustomerShellScreen(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/rides',
                  builder: (_, __) => const Text('rides-page'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const Text('stores-page'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/orders',
                  builder: (_, __) => const Text('orders-page'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  builder: (_, __) => const Text('cart-page'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, __) => const Text('profile-page'),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [cartItemCountProvider.overrideWithValue(0)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('Viajes'), findsOneWidget);
    expect(find.text('Tiendas'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);
    expect(find.text('Carrito'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    // Arranca en la pestaña de Viajes.
    expect(find.text('rides-page'), findsOneWidget);

    // La pestaña Tiendas (Comercio) sigue navegando.
    await tester.tap(find.text('Tiendas'));
    await tester.pumpAndSettle();
    expect(find.text('stores-page'), findsOneWidget);
  });
}
