import 'package:dts_customer/core/firebase/firebase_service.dart';
import 'package:dts_customer/features/notifications/application/push_notification_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

class FakeRemoteMessage extends Fake implements RemoteMessage {
  FakeRemoteMessage(this.data, {this.title, this.body});

  @override
  final Map<String, dynamic> data;

  @override
  RemoteNotification? get notification => RemoteNotification(
        title: title,
        body: body,
      );

  final String? title;
  final String? body;
}

void main() {
  late MockFirebaseService firebaseService;
  late PushNotificationHandler handler;
  String? navigatedTo;

  setUp(() {
    firebaseService = MockFirebaseService();
    navigatedTo = null;
    handler = PushNotificationHandler(
      firebaseService: firebaseService,
      navigate: (location) => navigatedTo = location,
    );
  });

  test('tap status push navega a tracking', () {
    final message = FakeRemoteMessage(
      {'order_id': '15', 'type': 'ON_THE_WAY'},
      title: 'Pedido en camino',
      body: 'Tu pedido ya salió',
    );

    handler.handleBackgroundMessage(message);
    handler.handleTap(
      PushNotificationPayload(orderId: 15, type: 'ON_THE_WAY'),
    );

    expect(navigatedTo, '/tracking/15');
  });

  test('tap chat_message navega a chat del pedido', () {
    handler.handleTap(
      PushNotificationPayload(orderId: 42, type: 'chat_message'),
    );

    expect(navigatedTo, '/orders/42/chat');
  });
}
