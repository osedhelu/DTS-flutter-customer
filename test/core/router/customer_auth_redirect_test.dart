import 'package:dts_customer/core/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('customer_home_location_is_rides_test', () {
    expect(customerHomeLocation, '/rides');
  });

  test('authenticated_at_splash_redirects_to_rides_test', () {
    expect(
      resolveCustomerAuthRedirect(auth: const AsyncData(true), loc: '/splash'),
      '/rides',
    );
  });

  test('authenticated_at_login_redirects_to_rides_test', () {
    expect(
      resolveCustomerAuthRedirect(auth: const AsyncData(true), loc: '/login'),
      '/rides',
    );
  });

  test('unauthenticated_protected_redirects_to_login_test', () {
    expect(
      resolveCustomerAuthRedirect(auth: const AsyncData(false), loc: '/rides'),
      '/login',
    );
  });

  test('loading_redirects_to_splash_test', () {
    expect(
      resolveCustomerAuthRedirect(auth: const AsyncLoading(), loc: '/rides'),
      '/splash',
    );
  });

  test('authenticated_inside_app_stays_test', () {
    expect(
      resolveCustomerAuthRedirect(auth: const AsyncData(true), loc: '/rides'),
      isNull,
    );
    expect(
      resolveCustomerAuthRedirect(auth: const AsyncData(true), loc: '/orders'),
      isNull,
    );
  });
}
