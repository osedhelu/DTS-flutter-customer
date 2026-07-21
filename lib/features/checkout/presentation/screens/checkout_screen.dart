import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/order.dart';
import '../../../profile/domain/entities/customer_profile.dart';
import '../../../profile/presentation/widgets/map_address_picker.dart';
import '../utils/api_error_detail.dart';
import '../utils/checkout_payment_helper.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();
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
      final profile =
          await ref.read(customerProfileRemoteDataSourceProvider).getProfile();
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
        } else if (profile.defaultAddress.isNotEmpty) {
          _addressController.text = profile.defaultAddress;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Descuento: \$${_discount.toStringAsFixed(2)}')),
      );
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

  Future<void> _confirm() async {
    final cart = ref.read(cartNotifierProvider);
    if (cart == null || cart.isEmpty) {
      setState(() => _error = 'El carrito está vacío');
      return;
    }
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() => _error = 'Ingresa una dirección de entrega');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final total = cart.total - _discount;

    try {
      final order = await ref.read(createOrderUseCaseProvider).call(
            CreateOrderParams(
              storeId: cart.storeId,
              items: cart.items
                  .map(
                    (item) => CreateOrderItem(
                      productId: item.product.id,
                      quantity: item.quantity,
                    ),
                  )
                  .toList(),
              deliveryAddress: address,
              customerNotes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
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
        isService: false,
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
      appBar: AppBar(title: const Text('Checkout')),
      body: cart == null || cart.isEmpty
          ? DtsEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Carrito vacío',
              message: 'Agrega productos para continuar.',
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
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.product.name} ×${item.quantity}',
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
                                  Text(
                                    '-\$${_discount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: theme.colorScheme.tertiary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
                                  key: const Key('checkout_total'),
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
                        title: 'Entrega',
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
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Dirección de entrega',
                                prefixIcon:
                                    const Icon(Icons.location_on_outlined),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.map_outlined),
                                  onPressed: _pickOnMap,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notas (opcional)',
                                prefixIcon: Icon(Icons.notes_outlined),
                              ),
                              maxLines: 2,
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
                              Text(
                                'Pago contra entrega (default)',
                                style: theme.textTheme.bodyMedium,
                              )
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
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          key: const Key('checkout_error'),
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
                            Text('Total a pagar', style: theme.textTheme.bodyMedium),
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
                          key: const Key('confirm_order_button'),
                          label: 'Confirmar pedido',
                          isLoading: _submitting,
                          onPressed: _confirm,
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
