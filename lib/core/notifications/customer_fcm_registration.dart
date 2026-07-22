import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../firebase/firebase_service.dart';
import '../../features/notifications/domain/usecases/register_fcm_token_usecase.dart';

/// Registro FCM del cliente: permiso, token (APNS retry), backend, refresh.
class CustomerFcmRegistration {
  CustomerFcmRegistration({
    required FirebaseService firebaseService,
    required RegisterFcmTokenUseCase registerFcmTokenUseCase,
    FirebaseMessaging? messaging,
  })  : _firebaseService = firebaseService,
        _registerFcmTokenUseCase = registerFcmTokenUseCase,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseService _firebaseService;
  final RegisterFcmTokenUseCase _registerFcmTokenUseCase;
  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _refreshSub;

  Future<bool> register({int apnsAttempts = 10}) async {
    if (kIsWeb) return false;
    try {
      // Usar Platform.isAndroid (host real); defaultTargetPlatform en tests es Android.
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }

      await _firebaseService.requestNotificationPermissionIfNeeded();

      if (!kIsWeb && Platform.isIOS) {
        String? apns;
        for (var i = 0; i < apnsAttempts; i++) {
          apns = await _messaging.getAPNSToken();
          if (apns != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        if (apns == null) {
          debugPrint(
            'CustomerFcmRegistration: APNS aún no listo; '
            'se reintentará con onTokenRefresh',
          );
          return false;
        }
      }

      final token = await _firebaseService.getFcmToken();
      if (token == null || token.isEmpty) {
        debugPrint('CustomerFcmRegistration: getFcmToken() vacío');
        return false;
      }

      await _registerFcmTokenUseCase.call(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      if (kDebugMode) {
        debugPrint(
          'CustomerFcmRegistration: token registrado (${token.length} chars)',
        );
      }
      return true;
    } catch (e, st) {
      debugPrint('CustomerFcmRegistration failed: $e');
      debugPrint('$st');
      return false;
    }
  }

  void listenTokenRefresh() {
    _refreshSub?.cancel();
    _refreshSub = _messaging.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      try {
        await _registerFcmTokenUseCase.call(
          token: token,
          platform: Platform.isIOS ? 'ios' : 'android',
        );
        if (kDebugMode) {
          debugPrint('CustomerFcmRegistration: token refresh registrado');
        }
      } catch (e) {
        debugPrint('CustomerFcmRegistration onTokenRefresh failed: $e');
      }
    });
  }

  void dispose() {
    _refreshSub?.cancel();
    _refreshSub = null;
  }
}
