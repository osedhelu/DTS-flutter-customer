import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/debug/agent_debug_log.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cart/application/providers/cart_providers.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../orders/presentation/screens/customer_orders_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../stores/presentation/screens/store_list_screen.dart';

class CustomerShellScreen extends ConsumerWidget {
  const CustomerShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.coral,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.coral,
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class ShellHomeScreen extends StatelessWidget {
  const ShellHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const StoreListScreen();
}

class ShellOrdersScreen extends StatelessWidget {
  const ShellOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => const CustomerOrdersScreen();
}

class ShellCartScreen extends StatelessWidget {
  const ShellCartScreen({super.key});

  @override
  Widget build(BuildContext context) => const CartScreen(embeddedInShell: true);
}

class ShellProfileScreen extends StatelessWidget {
  const ShellProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}

/// Prefiere el tab Carrito del shell; si no aplica, push standalone.
void goToCart(BuildContext context) {
  final loc = GoRouterState.of(context).matchedLocation;
  final useGo = loc == '/home' ||
      loc.startsWith('/orders') ||
      loc == '/cart' ||
      loc.startsWith('/profile');
  // #region agent log
  agentDebugLog(
    location: 'customer_shell_screen.dart:goToCart',
    message: 'goToCart navigation',
    hypothesisId: 'H3',
    data: {'loc': loc, 'mode': useGo ? 'go' : 'push'},
  );
  // #endregion
  if (useGo) {
    context.go('/cart');
  } else {
    context.push('/cart');
  }
}
