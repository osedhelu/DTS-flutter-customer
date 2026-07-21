import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/customer_profile.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  List<CustomerAddress> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items =
          await ref.read(customerProfileRemoteDataSourceProvider).listAddresses();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final label = TextEditingController(text: 'Casa');
    final address = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva dirección'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              decoration: const InputDecoration(labelText: 'Etiqueta'),
            ),
            TextField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true || address.text.trim().isEmpty) return;
    try {
      await ref.read(customerProfileRemoteDataSourceProvider).createAddress(
            label: label.text.trim(),
            address: address.text.trim(),
            isDefault: _items.isEmpty,
          );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Direcciones')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const DtsLoading()
          : _items.isEmpty
              ? DtsEmptyState(
                  icon: Icons.location_off_outlined,
                  title: 'Sin direcciones',
                  message: 'Agrega una dirección para agilizar el checkout.',
                  actionLabel: 'Agregar',
                  onAction: _add,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final a = _items[i];
                      return Card(
                        child: ListTile(
                          title: Text(a.label),
                          subtitle: Text(a.address),
                          trailing: a.isDefault
                              ? const DtsStatusChip(
                                  label: 'Default',
                                  tone: DtsChipTone.success,
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    await ref
                                        .read(
                                          customerProfileRemoteDataSourceProvider,
                                        )
                                        .deleteAddress(a.id);
                                    await _load();
                                  },
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
