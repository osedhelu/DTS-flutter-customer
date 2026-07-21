import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/customer_profile.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _photo = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _photo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p =
          await ref.read(customerProfileRemoteDataSourceProvider).getProfile();
      _name.text = p.fullName;
      _phone.text = p.phone;
      _address.text = p.defaultAddress;
      _photo.text = p.photoUrl;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(customerProfileRemoteDataSourceProvider).updateProfile(
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
            defaultAddress: _address.text.trim(),
            photoUrl: _photo.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: _loading
          ? const DtsLoading()
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  decoration:
                      const InputDecoration(labelText: 'Dirección default'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _photo,
                  decoration: const InputDecoration(labelText: 'URL foto'),
                ),
                const SizedBox(height: 24),
                DtsPrimaryButton(
                  label: 'Guardar',
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}
