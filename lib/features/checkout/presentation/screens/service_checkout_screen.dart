import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../cart/application/providers/cart_providers.dart';
import '../../../profile/domain/entities/customer_profile.dart';
import '../../../profile/presentation/widgets/map_address_picker.dart';
import '../../domain/entities/order.dart';
import '../utils/api_error_detail.dart';
import '../utils/checkout_payment_helper.dart';

class ServiceCheckoutScreen extends ConsumerStatefulWidget {
  const ServiceCheckoutScreen({super.key});

  @override
  ConsumerState<ServiceCheckoutScreen> createState() =>
      _ServiceCheckoutScreenState();
}

class _ServiceCheckoutScreenState extends ConsumerState<ServiceCheckoutScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();
  DateTime? _scheduledAt;
  bool _submitting = false;
  String? _error;
  List<CustomerAddress> _addresses = [];
  int? _selectedAddressId;
  double? _latitude;
  double? _longitude;
  List<Map<String, dynamic>> _paymentMethods = [];
  int? _selectedPaymentMethodId;
  double _discount = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cart = ref.read(cartNotifierProvider);
    if (cart == null) return;
    try {
      final addresses =
          await ref.read(customerProfileRemoteDataSourceProvider).listAddresses();
      final dio = ref.read(apiClientProvider).dio;
      final payments = await dio.get<List<dynamic>>(
        '/stores/${cart.storeId}/payment-methods/',
      );
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _paymentMethods = (payments.data ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (_paymentMethods.isNotEmpty) {
          _selectedPaymentMethodId = _paymentMethods.first['id'] as int?;
        }
        if (addresses.isNotEmpty) {
          final def = addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          );
          _selectedAddressId = def.id;
          _addressController.text = def.address;
          _latitude = def.latitude;
          _longitude = def.longitude;
        }
      });
    } catch (_) {}
  }

  Future<void> _validateCoupon() async {
    final cart = ref.read(cartNotifierProvider);
    if (cart == null) return;
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.post<Map<String, dynamic>>(
        '/marketing/coupons/validate/',
        data: {'code': code, 'order_total': cart.total.toStringAsFixed(2)},
      );
      setState(() {
        _discount = double.tryParse(
              res.data?['discount_amount']?.toString() ?? '0',
            ) ??
            0;
        _error = null;
      });
    } catch (_) {
      setState(() {
        _discount = 0;
        _error = 'Cupón no válido';
      });
    }
  }

  Future<void> _pickOnMap() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => MapAddressPicker(
        initialAddress: _addressController.text,
        initialLat: _latitude,
        initialLng: _longitude,
      ),
    );
    if (result == null) return;
    setState(() {
      _addressController.text = result['address'] as String? ?? '';
      _latitude = result['latitude'] as double?;
      _longitude = result['longitude'] as double?;
    });
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

    final total = cart.total - _discount;

    final itemNotes = cart.items
        .map((item) => item.notes?.trim())
        .whereType<String>()
        .where((note) => note.isNotEmpty)
        .join('\n\n');
    final userNotes = _notesController.text.trim();
    final combinedNotes = [
      if (itemNotes.isNotEmpty) itemNotes,
      if (userNotes.isNotEmpty) userNotes,
    ].join('\n\n');

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
              customerNotes: combinedNotes.isEmpty ? null : combinedNotes,
              scheduledAt: _scheduledAt,
              latitude: _latitude,
              longitude: _longitude,
              paymentMethodId: _selectedPaymentMethodId,
              couponCode: _couponController.text.trim().isEmpty
                  ? null
                  : _couponController.text.trim(),
            ),
          );
      ref.read(cartNotifierProvider.notifier).clear();
      if (!mounted) return;
      await completeOrderWithOptionalSandbox(
        context: context,
        ref: ref,
        orderId: order.id,
        total: total,
        paymentMethods: _paymentMethods,
        selectedPaymentMethodId: _selectedPaymentMethodId,
        isService: true,
      );
    } catch (e) {
      setState(
        () => _error = parseApiErrorDetail(
          e,
          fallback: 'No se pudo crear el pedido',
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);
    final theme = Theme.of(context);
    final total = (cart?.total ?? 0) - _discount;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout servicio')),
      body: cart == null || cart.isEmpty
          ? DtsEmptyState(
              icon: Icons.home_repair_service_outlined,
              title: 'Carrito vacío',
              message: 'Agrega un servicio para continuar.',
              actionLabel: 'Ir a inicio',
              onAction: () => context.go('/home'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      DtsSectionCard(
                        title: 'Resumen',
                        subtitle: cart.storeName,
                        child: Column(
                          children: [
                            for (final item in cart.items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${item.product.name} ×${item.quantity}',
                                          ),
                                          if (item.notes?.trim().isNotEmpty ??
                                              false)
                                            Text(
                                              item.notes!,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${item.subtotal.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_discount > 0) ...[
                              const Divider(),
                              Row(
                                children: [
                                  const Expanded(child: Text('Descuento')),
                                  Text('-\$${_discount.toStringAsFixed(2)}'),
                                ],
                              ),
                            ],
                            const Divider(),
                            Row(
                              children: [
                                Text(
                                  'Total',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      DtsSectionCard(
                        title: 'Ubicación del servicio',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_addresses.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _addresses
                                    .map(
                                      (a) => ChoiceChip(
                                        label: Text(a.label),
                                        selected: _selectedAddressId == a.id,
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedAddressId = a.id;
                                            _addressController.text = a.address;
                                            _latitude = a.latitude;
                                            _longitude = a.longitude;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              key: const Key('service_address_field'),
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Dirección del servicio',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.map_outlined),
                                  onPressed: _pickOnMap,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: const Key('service_notes_field'),
                              controller: _notesController,
                              decoration:
                                  const InputDecoration(labelText: 'Notas'),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              key: const Key('service_schedule_picker'),
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Horario preferido'),
                              subtitle: Text(
                                _scheduledAt?.toLocal().toString() ??
                                    'Sin definir',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _pickSchedule,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      DtsSectionCard(
                        title: 'Pago',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_paymentMethods.isEmpty)
                              const Text('Pago contra entrega (default)')
                            else
                              ..._paymentMethods.map(
                                (m) => RadioListTile<int>(
                                  contentPadding: EdgeInsets.zero,
                                  value: m['id'] as int,
                                  groupValue: _selectedPaymentMethodId,
                                  onChanged: (v) => setState(
                                    () => _selectedPaymentMethodId = v,
                                  ),
                                  title: Text(
                                    m['name']?.toString() ?? 'Método',
                                  ),
                                  subtitle:
                                      (m['instructions']?.toString() ?? '')
                                              .isNotEmpty
                                          ? Text(m['instructions'].toString())
                                          : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      DtsSectionCard(
                        title: 'Cupón',
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                decoration: const InputDecoration(
                                  labelText: 'Código',
                                  prefixIcon:
                                      Icon(Icons.local_offer_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _validateCoupon,
                              child: const Text('Aplicar'),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Total a pagar',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DtsPrimaryButton(
                          key: const Key('confirm_service_order_button'),
                          label: 'Confirmar solicitud',
                          isLoading: _submitting,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
