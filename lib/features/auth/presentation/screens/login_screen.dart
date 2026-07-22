import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/post_auth_service.dart';

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
      // No navegar aquí: setAuthenticated + redirect de GoRouter → /home.
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo iniciar sesión');
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

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.creamDeep,
              AppColors.cream,
            ],
            stops: const [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      const DtsBrandMark(size: 72, showWordmark: false),
                      const SizedBox(height: 16),
                      Text(
                        'DTS',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pide en tus comercios favoritos',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 36),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Iniciar sesión',
                            style: theme.textTheme.titleLarge,
                          ),
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
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
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
                              style: TextStyle(color: theme.colorScheme.error),
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
                          OutlinedButton.icon(
                            key: const Key('login_google'),
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Continuar con Google'),
                          ),
                          if (_showApple) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              key: const Key('login_apple'),
                              onPressed: _isLoading ? null : _signInWithApple,
                              icon: const Icon(Icons.apple),
                              label: const Text('Continuar con Apple'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () => context.go('/register'),
                  child: Text(
                    '¿Nuevo aquí? Crear cuenta',
                    style: TextStyle(color: scheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
