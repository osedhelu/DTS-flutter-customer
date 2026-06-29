import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/firebase/firebase_background_handler.dart';
import 'core/router/app_router.dart';
import 'features/notifications/application/push_notification_handler.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(const ProviderScope(child: DtsCustomerApp()));
}

class DtsCustomerApp extends ConsumerStatefulWidget {
  const DtsCustomerApp({super.key});

  @override
  ConsumerState<DtsCustomerApp> createState() => _DtsCustomerAppState();
}

class _DtsCustomerAppState extends ConsumerState<DtsCustomerApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrapPush);
  }

  Future<void> _bootstrapPush() async {
    if (kIsWeb) return;

    final firebaseService = ref.read(firebaseServiceProvider);
    await firebaseService.initialize();

    final handler = ref.read(pushNotificationHandlerProvider);
    await handler.initialize();

    if (!mounted) return;
    attachPushNavigation(
      handler: handler,
      router: ref.read(appRouterProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'DTS Cliente',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
