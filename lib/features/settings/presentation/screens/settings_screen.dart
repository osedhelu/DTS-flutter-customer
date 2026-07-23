import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/location_radius_constants.dart';
import '../../../../core/debug/agent_debug_log.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/domain/entities/customer_profile.dart';
import '../widgets/open_customer_search_zone_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;
  bool _loading = true;
  CustomerProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final profile =
          await ref.read(customerProfileRemoteDataSourceProvider).getProfile();
      if (!mounted) return;
      setState(() {
        _notifications = prefs.getBool('notifications_enabled') ?? true;
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notifications = prefs.getBool('notifications_enabled') ?? true;
        _loading = false;
      });
    }
  }

  Future<void> _openSearchZone() async {
    final updated = await openCustomerSearchZonePicker(
      context,
      ref,
      profile: _profile,
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  String get _searchZoneSubtitle {
    final radius = normalizeRadiusPreset(
      _profile?.searchRadiusKm ?? defaultRadiusKm,
    );
    if (_profile?.hasSearchCenter == true) {
      return 'Mostrando tiendas en ${radius.toStringAsFixed(0)} km';
    }
    return 'Sin zona definida · default ${defaultRadiusKm.toStringAsFixed(0)} km';
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
                  key: const Key('settings_search_zone_tile'),
                  leading: const Icon(Icons.radar_outlined),
                  title: const Text('Ubicación y radio de tiendas'),
                  subtitle: Text(_searchZoneSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openSearchZone,
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
                    // #region agent log
                    agentDebugLog(
                      location: 'settings_screen.dart:logout',
                      message: 'logout setAuthenticated(false) only',
                      hypothesisId: 'F3',
                      runId: 'post-fix',
                    );
                    // #endregion
                    // Sin invalidate (flicker loading) ni context.go (doble nav).
                    ref.read(authStateProvider.notifier).setAuthenticated(false);
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
