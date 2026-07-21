import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../orders/presentation/screens/customer_orders_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../stores/presentation/screens/store_list_screen.dart';

class CustomerShellScreen extends StatelessWidget {
  const CustomerShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
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

class ShellProfileScreen extends StatelessWidget {
  const ShellProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
