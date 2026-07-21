import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/firebase/firebase_background_handler.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/widgets.dart';
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      ref.read(connectivityOfflineProvider.notifier).state = offline;
    });

    if (kIsWeb) return;

    unawaited(_initPushStack());
  }

  Future<void> _initPushStack() async {
    final firebaseService = ref.read(firebaseServiceProvider);
    final handler = ref.read(pushNotificationHandlerProvider);

    await Future.wait([
      firebaseService.initialize(),
      handler.initialize(),
    ]);

    if (!mounted) return;
    attachPushNavigation(
      handler: handler,
      router: ref.read(appRouterProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final offline = ref.watch(connectivityOfflineProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'DTS Cliente',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        return Column(
          children: [
            DtsNetworkBanner(visible: offline),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
      routerConfig: router,
    );
  }
}
