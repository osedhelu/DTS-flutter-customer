import 'dart:async';

import 'package:dts_customer/core/debug/agent_debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router({Listenable? refresh}) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    observers: [AgentNavObserver(tag: 'fut')],
    redirect: (context, state) {
      if (refresh is ValueNotifier<bool>) {
        final authed = refresh.value;
        final loc = state.matchedLocation;
        if (!authed && loc != '/login') return '/login';
        if (authed && loc == '/login') return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const Text('login')),
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

  testWidgets('F1: go(/cart) mid push transition → Future already completed?',
      (tester) async {
    final router = _router();
    await tester.pumpWidget(
      MaterialApp.router(
        builder: (context, child) => Stack(
          children: [child ?? const SizedBox.shrink()],
        ),
        routerConfig: router,
      ),
    );
    await tester.pump();

    router.push('/stores/9');
    // Mid-transition: only one frame, do not settle.
    await tester.pump();

    Object? caught;
    await runZonedGuarded(() async {
      agentDebugLog(
        location: 'future_completed_test:F1',
        message: 'go cart mid push',
        hypothesisId: 'F1',
        data: {
          'uri': router.routerDelegate.currentConfiguration.uri.toString(),
        },
      );
      router.go('/cart');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    }, (e, st) {
      caught = e;
      agentDebugLog(
        location: 'future_completed_test:F1-catch',
        message: 'caught F1',
        hypothesisId: 'F1',
        data: {
          'error': e.toString(),
          'stackHead': st.toString().split('\n').take(8).join(' | '),
        },
      );
    });

    final take = tester.takeException();
    agentDebugLog(
      location: 'future_completed_test:F1-result',
      message: 'F1 done',
      hypothesisId: 'F1',
      data: {
        'caught': caught?.toString(),
        'takeException': take?.toString(),
      },
    );
  });

  testWidgets('F2: auth refresh notify mid push → Future already completed?',
      (tester) async {
    final auth = ValueNotifier<bool>(true);
    final router = _router(refresh: auth);
    await tester.pumpWidget(
      MaterialApp.router(
        builder: (context, child) => Stack(
          children: [child ?? const SizedBox.shrink()],
        ),
        routerConfig: router,
      ),
    );
    await tester.pump();

    router.push('/stores/9');
    await tester.pump(); // mid transition

    Object? caught;
    await runZonedGuarded(() async {
      agentDebugLog(
        location: 'future_completed_test:F2',
        message: 'auth notify mid push',
        hypothesisId: 'F2',
      );
      // Toggle false→true forces redirect refresh while store push animates.
      auth.value = false;
      await tester.pump();
      auth.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }, (e, st) {
      caught = e;
      agentDebugLog(
        location: 'future_completed_test:F2-catch',
        message: 'caught F2',
        hypothesisId: 'F2',
        data: {
          'error': e.toString(),
          'stackHead': st.toString().split('\n').take(8).join(' | '),
        },
      );
    });

    final take = tester.takeException();
    agentDebugLog(
      location: 'future_completed_test:F2-result',
      message: 'F2 done',
      hypothesisId: 'F2',
      data: {
        'caught': caught?.toString(),
        'takeException': take?.toString(),
      },
    );
  });

  testWidgets('F3: invalidate-like double nav logout', (tester) async {
    final auth = ValueNotifier<bool>(true);
    final router = _router(refresh: auth);
    await tester.pumpWidget(
      MaterialApp.router(
        builder: (context, child) => Stack(
          children: [child ?? const SizedBox.shrink()],
        ),
        routerConfig: router,
      ),
    );
    await tester.pump();
    router.push('/stores/9');
    await tester.pumpAndSettle();

    Object? caught;
    await runZonedGuarded(() async {
      agentDebugLog(
        location: 'future_completed_test:F3',
        message: 'logout double nav',
        hypothesisId: 'F3',
      );
      auth.value = false; // redirect → /login
      router.go('/login'); // explicit go like settings
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }, (e, st) {
      caught = e;
      agentDebugLog(
        location: 'future_completed_test:F3-catch',
        message: 'caught F3',
        hypothesisId: 'F3',
        data: {
          'error': e.toString(),
          'stackHead': st.toString().split('\n').take(8).join(' | '),
        },
      );
    });

    final take = tester.takeException();
    agentDebugLog(
      location: 'future_completed_test:F3-result',
      message: 'F3 done',
      hypothesisId: 'F3',
      data: {
        'caught': caught?.toString(),
        'takeException': take?.toString(),
      },
    );
  });
}
