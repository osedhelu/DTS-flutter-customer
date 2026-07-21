import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/post_auth_service.dart';
import '../../domain/usecases/register_usecase.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(registerUseCaseProvider).call(
            RegisterCustomerParams(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              phone: _phoneController.text.trim(),
            ),
          );
      ref.read(postAuthServiceProvider).complete(ref);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo crear la cuenta');
      }
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    // Redirect de GoRouter → /home tras invalidate de auth.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.creamDeep, AppColors.cream],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Center(
                    child: DtsBrandMark(size: 64, showWordmark: false),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Crear cuenta',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Regístrate y empieza a pedir en minutos',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextFormField(
                            key: const Key('register_username'),
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('register_email'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('register_phone'),
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              hintText: '+573001234567',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('register_password'),
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (v) => v == null || v.length < 8
                                ? 'Mínimo 8 caracteres'
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(color: scheme.error),
                            ),
                          ],
                          const SizedBox(height: 20),
                          DtsPrimaryButton(
                            key: const Key('register_submit'),
                            onPressed: _isLoading ? null : _submit,
                            label: 'Registrarme',
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Ya tengo cuenta',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
