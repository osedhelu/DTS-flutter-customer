import 'dart:async';

import 'package:dts_customer/core/debug/agent_debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('H3b: push shell /cart from sibling then router.pop',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      observers: [AgentNavObserver(tag: 'h3b')],
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
        GoRoute(
          path: '/stores/:id',
          builder: (context, __) => Scaffold(
            appBar: AppBar(title: const Text('store')),
            body: ElevatedButton(
              onPressed: () => context.push('/cart'),
              child: const Text('to-cart'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    router.push('/stores/9');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('to-cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    agentDebugLog(
      location: 'h3b:beforePop',
      message: 'about to router.pop after push /cart',
      hypothesisId: 'H3',
      data: {
        'canPop': router.canPop(),
        'uri': router.routerDelegate.currentConfiguration.uri.toString(),
      },
    );

    Object? caught;
    await runZonedGuarded(() async {
      // Prefer GoRouter.pop (same as AppBar back via maybePop path often).
      if (router.canPop()) {
        router.pop();
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }, (e, st) {
      caught = e;
      agentDebugLog(
        location: 'h3b:catch',
        message: 'caught router.pop',
        hypothesisId: 'H3',
        data: {
          'error': e.toString(),
          'stackHead': st.toString().split('\n').take(12).join(' | '),
        },
      );
    });

    agentDebugLog(
      location: 'h3b:result',
      message: 'H3b finished',
      hypothesisId: 'H3',
      data: {'caught': caught?.toString()},
    );

    // Also try Navigator.maybePop on root.
    Object? caught2;
    await runZonedGuarded(() async {
      router.push('/stores/9');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('to-cart'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final navState = router.routerDelegate.navigatorKey.currentState;
      agentDebugLog(
        location: 'h3b:beforeMaybePop',
        message: 'Navigator.maybePop',
        hypothesisId: 'H3',
        data: {
          'navNull': navState == null,
          'canPop': navState?.canPop(),
        },
      );
      await navState?.maybePop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }, (e, st) {
      caught2 = e;
      agentDebugLog(
        location: 'h3b:maybePopCatch',
        message: 'caught maybePop',
        hypothesisId: 'H3',
        data: {
          'error': e.toString(),
          'stackHead': st.toString().split('\n').take(12).join(' | '),
        },
      );
    });

    agentDebugLog(
      location: 'h3b:maybePopResult',
      message: 'H3b maybePop finished',
      hypothesisId: 'H3',
      data: {'caught': caught2?.toString()},
    );
  });

  testWidgets('H2b: sheet + receipt + popUntil + sheet pop (real flow)',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/checkout',
      observers: [AgentNavObserver(tag: 'h2b')],
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, __) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                await showModalBottomSheet<bool>(
                  context: context,
                  builder: (sheetCtx) {
                    return ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(sheetCtx).push<void>(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: const Text('receipt')),
                              body: ElevatedButton(
                                onPressed: () {
                                  agentDebugLog(
                                    location: 'h2b:popUntil',
                                    message: 'popUntil isFirst from receipt',
                                    hypothesisId: 'H2',
                                  );
                                  Navigator.of(sheetCtx)
                                      .popUntil((r) => r.isFirst);
                                },
                                child: const Text('ver-pedido'),
                              ),
                            ),
                          ),
                        );
                        if (sheetCtx.mounted) {
                          agentDebugLog(
                            location: 'h2b:sheetPop',
                            message: 'sheet trying Navigator.pop(true)',
                            hypothesisId: 'H2',
                          );
                          Navigator.of(sheetCtx).pop(true);
                        }
                      },
                      child: const Text('pay'),
                    );
                  },
                );
                if (context.mounted) {
                  agentDebugLog(
                    location: 'h2b:go',
                    message: 'context.go after sheet',
                    hypothesisId: 'H2',
                  );
                  context.go('/home');
                }
              },
              child: const Text('open-sheet'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    Object? caught;
    await runZonedGuarded(() async {
      await tester.tap(find.text('open-sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('pay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('ver-pedido'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }, (e, st) {
      caught = e;
      agentDebugLog(
        location: 'h2b:catch',
        message: 'caught sandbox-like flow',
        hypothesisId: 'H2',
        data: {
          'error': e.toString(),
          'stackHead': st.toString().split('\n').take(12).join(' | '),
        },
      );
    });

    agentDebugLog(
      location: 'h2b:result',
      message: 'H2b finished',
      hypothesisId: 'H2',
      data: {'caught': caught?.toString()},
    );
  });
}
