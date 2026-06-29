import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/application/providers/cart_providers.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/order.dart';

class ServiceCheckoutScreen extends ConsumerStatefulWidget {
  const ServiceCheckoutScreen({super.key});

  @override
  ConsumerState<ServiceCheckoutScreen> createState() =>
      _ServiceCheckoutScreenState();
}

class _ServiceCheckoutScreenState extends ConsumerState<ServiceCheckoutScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _scheduledAt;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final cart = ref.read(cartNotifierProvider);
    if (cart == null || cart.isEmpty) {
      setState(() => _error = 'El carrito está vacío');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      setState(() => _error = 'La dirección es obligatoria');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final order = await ref.read(createServiceOrderUseCaseProvider).call(
            CreateServiceOrderParams(
              storeId: cart.storeId,
              items: cart.items
                  .map(
                    (item) => CreateOrderItem(
                      productId: item.product.id,
                      quantity: item.quantity,
                    ),
                  )
                  .toList(),
              serviceAddress: _addressController.text.trim(),
              customerNotes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              scheduledAt: _scheduledAt,
            ),
          );
      ref.read(cartNotifierProvider.notifier).clear();
      if (!mounted) return;
      context.go('/orders/${order.id}/service-tracking');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout servicio')),
      body: cart == null
          ? const Center(child: Text('Carrito vacío'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('service_address_field'),
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección del servicio',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('service_notes_field'),
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    key: const Key('service_schedule_picker'),
                    title: const Text('Horario preferido'),
                    subtitle: Text(
                      _scheduledAt?.toLocal().toString() ?? 'Sin definir',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickSchedule,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('confirm_service_order_button'),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const CircularProgressIndicator()
                          : const Text('Confirmar solicitud'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
