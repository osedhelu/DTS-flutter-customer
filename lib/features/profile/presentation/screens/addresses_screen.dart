import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../checkout/presentation/utils/api_error_detail.dart';
import '../../domain/entities/customer_profile.dart';
import '../widgets/map_address_picker.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  List<CustomerAddress> _items = [];
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
      final items =
          await ref.read(customerProfileRemoteDataSourceProvider).listAddresses();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = parseApiErrorDetail(
          e,
          fallback: 'No se pudieron cargar las direcciones',
        );
      });
    }
  }

  Future<void> _add() async {
    final labelController = TextEditingController(text: 'Casa');
    final labelOk = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva dirección'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(labelText: 'Etiqueta (Casa, Oficina…)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (labelOk != true || !mounted) {
      labelController.dispose();
      return;
    }
    final label = labelController.text.trim().isEmpty
        ? 'Casa'
        : labelController.text.trim();
    labelController.dispose();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const MapAddressPicker(initialAddress: ''),
    );
    if (result == null || !mounted) return;

    final address = (result['address'] as String? ?? '').trim();
    final lat = result['latitude'] as double?;
    final lng = result['longitude'] as double?;
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el texto de la dirección')),
      );
      return;
    }
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la ubicación en el mapa')),
      );
      return;
    }

    try {
      await ref.read(customerProfileRemoteDataSourceProvider).createAddress(
            label: label,
            address: address,
            latitude: lat,
            longitude: lng,
            isDefault: _items.isEmpty,
          );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parseApiErrorDetail(e, fallback: 'No se pudo crear la dirección'),
          ),
        ),
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
          : _error != null
              ? DtsEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error',
                  message: _error!,
                  actionLabel: 'Reintentar',
                  onAction: _load,
                )
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
                                        try {
                                          await ref
                                              .read(
                                                customerProfileRemoteDataSourceProvider,
                                              )
                                              .deleteAddress(a.id);
                                          await _load();
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                parseApiErrorDetail(
                                                  e,
                                                  fallback:
                                                      'No se pudo eliminar',
                                                ),
                                              ),
                                            ),
                                          );
                                        }
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
