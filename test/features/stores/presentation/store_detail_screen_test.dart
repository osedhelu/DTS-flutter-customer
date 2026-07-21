import 'package:dio/dio.dart';
import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/core/network/api_client.dart';
import 'package:dts_customer/core/network/token_storage.dart';
import 'package:dts_customer/features/stores/presentation/screens/store_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../helpers/test_providers.dart';

ApiClient _apiClientReturning(Map<String, dynamic> detail) {
  final storage = InMemoryTokenStorage();
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: detail,
          ),
        );
      },
    ),
  );
  return ApiClient(tokenStorage: storage, dio: dio);
}

void main() {
  testWidgets('store_detail_loads_and_opens_catalog_test', (tester) async {
    final apiClient = _apiClientReturning({
      'id': 3,
      'name': 'Mi casa rapida',
      'description': 'Delivery demo',
      'is_open': true,
      'accepts_orders': true,
      'logo_url': null,
      'latitude': null,
      'longitude': null,
    });

    final router = GoRouter(
      initialLocation: '/stores/3',
      routes: [
        GoRoute(
          path: '/stores/:storeId',
          builder: (_, state) => StoreDetailScreen(
            storeId: int.parse(state.pathParameters['storeId']!),
          ),
          routes: [
            GoRoute(
              path: 'catalog',
              builder: (_, state) => Scaffold(
                body: Text('catalog-${state.pathParameters['storeId']}'),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mi casa rapida'), findsWidgets);
    expect(find.text('Ver catálogo'), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);

    await tester.tap(find.text('Ver catálogo'));
    await tester.pumpAndSettle();
    expect(find.text('catalog-3'), findsOneWidget);
  });

  testWidgets('store_detail_hides_map_without_coords_test', (tester) async {
    final apiClient = _apiClientReturning({
      'id': 1,
      'name': 'Sin mapa',
      'description': '',
      'is_open': true,
      'accepts_orders': true,
      'latitude': null,
      'longitude': null,
    });

    await tester.pumpWidget(
      buildTestApp(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
        child: const MaterialApp(home: StoreDetailScreen(storeId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin mapa'), findsWidgets);
    expect(find.byType(GoogleMap), findsNothing);
  });
}
