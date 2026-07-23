import 'dart:async';

import 'package:dts_customer/core/debug/agent_debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    observers: [AgentNavObserver(tag: 'post')],
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'H'),
                NavigationDestination(
                  icon: Icon(Icons.shopping_bag),
                  label: 'C',
                ),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const Text('home')),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/cart', builder: (_, __) => const Text('cart')),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/stores/:id',
        builder: (_, __) => const Scaffold(body: Text('store')),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('post-fix: go(/cart) then maybePop does not null-check',
      (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    router.push('/stores/9');
    await tester.pump();
    // Fixed pattern: go (not push) into shell cart tab.
    router.go('/cart');
    await tester.pump();

    final nav = router.routerDelegate.navigatorKey.currentState;
    agentDebugLog(
      location: 'maybe_pop_cart_test:post-fix-before',
      message: 'before maybePop after go cart',
      hypothesisId: 'H3',
      runId: 'post-fix',
      data: {
        'canPop': nav?.canPop(),
        'routerCanPop': router.canPop(),
        'uri': router.routerDelegate.currentConfiguration.uri.toString(),
        'matches': router.routerDelegate.currentConfiguration.matches
            .map((m) => m.matchedLocation)
            .toList()
            .toString(),
      },
    );

    Object? caught;
    await runZonedGuarded(() async {
      final result = await nav!.maybePop();
      agentDebugLog(
        location: 'maybe_pop_cart_test:post-fix-after',
        message: 'maybePop returned OK',
        hypothesisId: 'H3',
        runId: 'post-fix',
        data: {'result': result},
      );
      await tester.pump();
    }, (e, stack) {
      caught = e;
      agentDebugLog(
        location: 'maybe_pop_cart_test:post-fix-catch',
        message: 'caught maybePop post-fix',
        hypothesisId: 'H3',
        runId: 'post-fix',
        data: {
          'error': e.toString(),
          'stackHead': stack.toString().split('\n').take(10).join(' | '),
        },
      );
    });

    expect(caught, isNull);
  });
}
