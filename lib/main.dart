import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/debug/agent_debug_log.dart';
import 'core/firebase/firebase_background_handler.dart';
import 'core/notifications/customer_fcm_registration.dart';
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
      location: 'main.dart:FlutterError',
      message: 'FlutterError.onError',
      hypothesisId: 'F4',
      runId: 'post-fix',
      data: {
        'error': details.exceptionAsString(),
        'library': details.library,
        'stackHead':
            details.stack?.toString().split('\n').take(8).join(' | ') ?? '',
      },
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
  CustomerFcmRegistration? _fcmRegistration;
  bool? _lastOfflineLogged;
  ThemeMode? _lastThemeLogged;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _fcmRegistration?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      ref.read(connectivityOfflineProvider.notifier).state = offline;
    });

    final auth = await ref.read(authStateProvider.future);
    if (auth) {
      unawaited(ref.read(cartNotifierProvider.notifier).hydrate());
    }

    if (kIsWeb) return;

    unawaited(_initPushStack(authenticated: auth));
  }

  Future<void> _initPushStack({required bool authenticated}) async {
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

    if (authenticated) {
      _fcmRegistration = CustomerFcmRegistration(
        firebaseService: firebaseService,
        registerFcmTokenUseCase: ref.read(registerFcmTokenUseCaseProvider),
      );
      _fcmRegistration!.listenTokenRefresh();
      final ok = await _fcmRegistration!.register();
      if (!ok) {
        debugPrint(
          'Bootstrap: FCM no registrado aún (permiso/APNS); '
          'onTokenRefresh reintentará',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // read: evita recrear MaterialApp.router si el Provider se notifica.
    final router = ref.read(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // #region agent log
    if (_lastThemeLogged != themeMode) {
      _lastThemeLogged = themeMode;
      agentDebugLog(
        location: 'main.dart:build',
        message: 'themeMode applied to MaterialApp',
        hypothesisId: 'F4',
        runId: 'post-fix',
        data: {'themeMode': themeMode.name},
      );
    }
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
            // #region agent log
            if (_lastOfflineLogged != offline) {
              _lastOfflineLogged = offline;
              agentDebugLog(
                location: 'main.dart:MaterialApp.builder',
                message: 'connectivity banner toggle',
                hypothesisId: 'H5',
                data: {
                  'offline': offline,
                  'hasChild': child != null,
                },
              );
            }
            // #endregion
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
