import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/debug/agent_debug_log.dart';
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

  // #region agent log
  FlutterError.onError = (details) {
    agentDebugLog(
      hypothesisId: 'E',
      location: 'main.dart:FlutterError.onError',
      message: details.exceptionAsString(),
      data: {
        'library': details.library,
        'stack': details.stack?.toString().split('\n').take(8).join(' | '),
      },
      runId: 'post-fix-3',
    );
    FlutterError.presentError(details);
  };
  // #endregion

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
  int? _lastRouterHash;

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
    // Hipótesis V: NO watch auth aquí — evita rebuild de MaterialApp.router
    // al mismo tiempo que refreshListenable actualiza páginas del Navigator.
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // #region agent log
    final routerChanged =
        _lastRouterHash != null && _lastRouterHash != router.hashCode;
    agentDebugLog(
      hypothesisId: 'V',
      location: 'main.dart:DtsCustomerApp.build',
      message: 'MaterialApp.router build (stable; no auth watch)',
      data: {
        'routerHash': router.hashCode,
        'routerChanged': routerChanged,
        'prevRouterHash': _lastRouterHash,
        'themeMode': themeMode.toString(),
      },
      runId: 'post-fix-3',
    );
    _lastRouterHash = router.hashCode;
    // #endregion

    return MaterialApp.router(
      title: 'DTS Cliente',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final offline = ref.watch(connectivityOfflineProvider);
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (offline)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: DtsNetworkBanner(visible: true),
                  ),
              ],
            );
          },
        );
      },
      routerConfig: router,
    );
  }
}
