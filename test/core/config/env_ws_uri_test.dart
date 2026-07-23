import 'package:flutter_test/flutter_test.dart';

import 'package:dts_customer/core/config/env.dart';

void main() {
  test('buildWsUri fuerza puerto 443 en wss', () {
    final uri = EnvConfig.buildWsUri('/ws/orders/53/chat/?token=abc');
    expect(uri.scheme, 'wss');
    expect(uri.port, 443);
    expect(uri.toString().contains(':0'), isFalse);
  });
}
