import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/customer_profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  CustomerProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile =
          await ref.read(customerProfileRemoteDataSourceProvider).getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el perfil';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(authStateProvider.notifier).setAuthenticated(false);
    // Redirect de GoRouter lleva a /login; no context.go (evita doble nav).
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _loading
          ? const DtsLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      backgroundImage: (p?.photoUrl.isNotEmpty ?? false)
                          ? NetworkImage(p!.photoUrl)
                          : null,
                      child: (p?.photoUrl.isEmpty ?? true)
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      p?.fullName.isNotEmpty == true
                          ? p!.fullName
                          : 'Cliente',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (p?.email.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        p!.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  if (_error != null)
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  const SizedBox(height: 24),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_outlined),
                          title: const Text('Editar perfil'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final ok = await context.push('/profile/edit');
                            if (ok == true) _load();
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Mis direcciones'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/addresses'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Ajustes'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/settings'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Ayuda'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/help'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (p != null)
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Correo'),
                          trailing: Text(p.email.isEmpty ? '—' : p.email),
                        ),
                        const Divider(height: 1),
                        ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Teléfono'),
                            trailing: Text(p.phone.isEmpty ? '—' : p.phone),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.home_outlined),
                            title: const Text('Dirección default'),
                            subtitle: Text(
                              p.defaultAddress.isEmpty
                                  ? 'Sin dirección'
                                  : p.defaultAddress,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
