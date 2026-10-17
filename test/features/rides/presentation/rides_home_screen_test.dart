import 'package:dts_customer/features/rides/presentation/screens/rides_home_screen.dart';
import 'package:dts_customer/features/rides/presentation/widgets/rides_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/test_providers.dart';
import 'rides_widget_helpers.dart';

void main() {
  testWidgets('rides_home_picker_and_navigate_to_quote_test', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      initialLocation: '/rides',
      routes: [
        GoRoute(path: '/rides', builder: (_, __) => const RidesHomeScreen()),
        GoRoute(
          path: '/rides/quote',
          builder: (_, __) => const Text('quote-screen'),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          ridesMapBuilderProvider.overrideWithValue(fakeRidesMapBuilder),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('rides_home_screen')), findsOneWidget);
    expect(find.byKey(const Key('pickup_dropoff_picker')), findsOneWidget);

    // Primer tap fija el origen; segundo tap fija el destino.
    await tester.tap(find.byKey(const Key('fake_map_tap')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('fake_map_tap')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('ride_continue_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ride_continue_button')));
    await tester.pumpAndSettle();

    expect(find.text('quote-screen'), findsOneWidget);
  });
}
