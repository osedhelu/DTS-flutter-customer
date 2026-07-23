import 'dart:async';

import 'package:dts_customer/core/debug/agent_debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'F4: themeMode rebuild + splash→home same window → Future completed?',
      (tester) async {
    final auth = ValueNotifier<AsyncValue<bool>>(const AsyncLoading());
    final themeTick = ValueNotifier(0);

    final router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      observers: [AgentNavObserver(tag: 'f4')],
      redirect: (context, state) {
        final a = auth.value;
        final loc = state.matchedLocation;
        if (!a.hasValue && !a.hasError) {
          return loc == '/splash' ? null : '/splash';
        }
        final ok = a.requireValue;
        if (loc == '/splash') return ok ? '/home' : '/login';
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
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const Text('home'),
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
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ValueListenableBuilder<int>(
        valueListenable: themeTick,
        builder: (context, tick, _) {
          return MaterialApp.router(
            themeMode: tick.isEven ? ThemeMode.light : ThemeMode.dark,
            builder: (context, child) => Stack(
              children: [child ?? const SizedBox.shrink()],
            ),
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pump();

    Object? caught;
    Object? flutterErr;
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      flutterErr = details.exception;
      agentDebugLog(
        location: 'f4:FlutterError',
        message: 'FlutterError during F4',
        hypothesisId: 'F4',
        data: {
          'error': details.exceptionAsString(),
          'stackHead':
              details.stack?.toString().split('\n').take(6).join(' | ') ?? '',
        },
      );
    };

    await runZonedGuarded(() async {
      // Same window: auth resolves + MaterialApp theme rebuild.
      auth.value = const AsyncData(true);
      themeTick.value = 1;
      await tester.pump();
      themeTick.value = 2;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }, (e, st) {
      caught = e;
      agentDebugLog(
        location: 'f4:catch',
        message: 'zone caught',
        hypothesisId: 'F4',
        data: {
          'error': e.toString(),
          'stackHead': st.toString().split('\n').take(8).join(' | '),
        },
      );
    });

    FlutterError.onError = oldOnError;
    final take = tester.takeException();
    agentDebugLog(
      location: 'f4:result',
      message: 'F4 done',
      hypothesisId: 'F4',
      data: {
        'caught': caught?.toString(),
        'flutterErr': flutterErr?.toString(),
        'takeException': take?.toString(),
        'hasHome': find.text('home').evaluate().isNotEmpty,
      },
    );
  });

  testWidgets(
      'F5: recreate GoRouter instance mid-frame (watch provider pattern)',
      (tester) async {
    final auth = ValueNotifier<AsyncValue<bool>>(const AsyncData(true));
    var routerGen = 0;

    GoRouter buildRouter() {
      routerGen++;
      return GoRouter(
        initialLocation: '/home',
        refreshListenable: auth,
        observers: [AgentNavObserver(tag: 'f5-$routerGen')],
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                Scaffold(body: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (_, __) => const Text('home'),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/stores/:id',
            builder: (_, __) => const Text('store'),
          ),
        ],
      );
    }

    final routerNotifier = ValueNotifier<GoRouter>(buildRouter());

    await tester.pumpWidget(
      ValueListenableBuilder<GoRouter>(
        valueListenable: routerNotifier,
        builder: (context, router, _) {
          return MaterialApp.router(
            builder: (context, child) => Stack(
              children: [child ?? const SizedBox.shrink()],
            ),
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pump();

    routerNotifier.value.push('/stores/1');
    await tester.pump(); // mid transition

    Object? flutterErr;
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      flutterErr = details.exception;
      agentDebugLog(
        location: 'f5:FlutterError',
        message: 'FlutterError during F5',
        hypothesisId: 'F5',
        data: {'error': details.exceptionAsString()},
      );
    };

    // Recreate GoRouter while previous push is in flight (simulates provider rebuild).
    routerNotifier.value = buildRouter();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    FlutterError.onError = oldOnError;
    final take = tester.takeException();
    agentDebugLog(
      location: 'f5:result',
      message: 'F5 done',
      hypothesisId: 'F5',
      data: {
        'flutterErr': flutterErr?.toString(),
        'takeException': take?.toString(),
        'routerGen': routerGen,
      },
    );
  });
}
