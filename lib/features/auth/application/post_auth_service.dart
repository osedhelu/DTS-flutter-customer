import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../notifications/domain/usecases/register_fcm_token_usecase.dart';

class PostAuthService {
  const PostAuthService({
    required RegisterFcmTokenUseCase registerFcmTokenUseCase,
    required FirebaseService firebaseService,
  })  : _registerFcmTokenUseCase = registerFcmTokenUseCase,
        _firebaseService = firebaseService;

  final RegisterFcmTokenUseCase _registerFcmTokenUseCase;
  final FirebaseService _firebaseService;

  /// Marca sesión autenticada sin pasar por `loading` (evita race en Navigator).
  void complete(WidgetRef ref) {
    ref.read(authStateProvider.notifier).setAuthenticated(true);
    unawaited(_registerPushInBackground());
  }

  Future<void> _registerPushInBackground() async {
    if (kIsWeb) return;

    try {
      await _firebaseService.requestNotificationPermissionIfNeeded();
      final token = await _firebaseService.getFcmToken();
      if (token != null && token.isNotEmpty) {
        await _registerFcmTokenUseCase.call(
          token: token,
          platform: _platformName(),
        );
      }
    } catch (_) {
      // Push es best-effort; no bloquear login si FCM falla.
    }
  }

  String _platformName() {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}

final postAuthServiceProvider = Provider<PostAuthService>((ref) {
  return PostAuthService(
    registerFcmTokenUseCase: ref.watch(registerFcmTokenUseCaseProvider),
    firebaseService: ref.watch(firebaseServiceProvider),
  );
});
