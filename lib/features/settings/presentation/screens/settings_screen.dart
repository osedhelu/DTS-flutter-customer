import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifications = prefs.getBool('notifications_enabled') ?? true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: _loading
          ? const DtsLoading()
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Notificaciones'),
                  value: _notifications,
                  onChanged: (v) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_enabled', v);
                    setState(() => _notifications = v);
                  },
                ),
                ListTile(
                  title: const Text('Tema'),
                  subtitle: Text(_themeLabel(ref.watch(themeModeProvider))),
                  trailing: DropdownButton<ThemeMode>(
                    value: ref.watch(themeModeProvider),
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('Sistema'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Claro'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Oscuro'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).setMode(mode);
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Recuperar contraseña'),
                  onTap: () => context.push('/forgot-password'),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Soporte'),
                  onTap: () => launchUrl(
                    Uri.parse('mailto:soporte@dtsdelivery.com'),
                  ),
                ),
                const ListTile(
                  title: Text('Versión'),
                  trailing: Text('0.1.0'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    await ref.read(authRepositoryProvider).logout();
                    ref.invalidate(authStateProvider);
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Claro',
        ThemeMode.dark => 'Oscuro',
        ThemeMode.system => 'Sistema',
      };
}
