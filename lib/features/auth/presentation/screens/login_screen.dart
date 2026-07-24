import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/post_auth_service.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/social_auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _afterAuth(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await action();
      ref.read(postAuthServiceProvider).complete(ref);
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        debugPrint('Google/login error: $msg');
        setState(() {
          if (msg.contains('cancelado') || msg.contains('canceled')) {
            _error = 'Inicio de sesión cancelado';
          } else if (msg.contains('ApiException: 10') ||
              msg.contains('DEVELOPER_ERROR')) {
            _error =
                'Error de configuración Google (SHA-1 / package). Revisa Firebase.';
          } else if (msg.contains('network') ||
              msg.contains('SocketException')) {
            _error = 'Sin conexión. Revisa tu red e inténtalo de nuevo.';
          } else if (msg.contains('401') ||
              msg.contains('403') ||
              msg.contains('Token de Firebase')) {
            _error = 'El servidor rechazó el login con Google.';
          } else {
            final short = msg.length > 140 ? '${msg.substring(0, 140)}…' : msg;
            _error = short.replaceFirst(RegExp(r'^Exception:\s*'), '');
          }
        });
      }
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _afterAuth(
      () => ref.read(loginUseCaseProvider).call(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          ),
    );
  }

  Future<void> _signInWithGoogle() async {
    await _afterAuth(() => ref.read(googleSignInUseCaseProvider).call());
  }

  Future<void> _signInWithApple() async {
    await _afterAuth(() => ref.read(appleSignInUseCaseProvider).call());
  }

  bool get _showApple => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthScaffold(
      header: Column(
        children: [
          const DtsBrandMark(size: 88, showWordmark: false),
          const SizedBox(height: 12),
          Text(
            'Pide en tus comercios favoritos',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      body: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Iniciar sesión', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('login_username'),
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('login_password'),
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requerido' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => context.push('/forgot-password'),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                DtsPrimaryButton(
                  key: const Key('login_submit'),
                  label: 'Entrar',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                SocialAuthButtons(
                  enabled: !_isLoading,
                  showApple: _showApple,
                  onGoogle: _signInWithGoogle,
                  onApple: _signInWithApple,
                ),
              ],
            ),
          ),
        ),
      ),
      footer: TextButton(
        onPressed: _isLoading ? null : () => context.go('/register'),
        child: const Text('¿Nuevo aquí? Crear cuenta'),
      ),
    );
  }
}
