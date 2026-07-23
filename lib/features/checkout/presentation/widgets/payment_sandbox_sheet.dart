import 'package:flutter/material.dart';

import '../../../../core/debug/agent_debug_log.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/payment_receipt.dart';
import '../screens/payment_receipt_screen.dart';

class PaymentSandboxSheet extends StatefulWidget {
  const PaymentSandboxSheet({
    super.key,
    required this.total,
    required this.onPay,
  });

  final double total;

  /// Cobra y devuelve el recibo; el sheet lo muestra inline (sin Navigator.push).
  final Future<PaymentReceipt> Function(String cardLast4) onPay;

  static Future<bool?> show(
    BuildContext context, {
    required double total,
    required Future<PaymentReceipt> Function(String cardLast4) onPay,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PaymentSandboxSheet(total: total, onPay: onPay),
    );
  }

  @override
  State<PaymentSandboxSheet> createState() => _PaymentSandboxSheetState();
}

class _PaymentSandboxSheetState extends State<PaymentSandboxSheet> {
  final _cardController = TextEditingController(text: '4242424242424242');
  final _expiryController = TextEditingController(text: '12/30');
  final _cvvController = TextEditingController(text: '123');
  bool _loading = false;
  PaymentReceipt? _receipt;

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final digits = _cardController.text.replaceAll(RegExp(r'\D'), '');
      final last4 =
          digits.length >= 4 ? digits.substring(digits.length - 4) : '4242';
      final receipt = await widget.onPay(last4);
      if (!mounted) return;
      // #region agent log
      agentDebugLog(
        location: 'payment_sandbox_sheet.dart:_submit',
        message: 'showing receipt inline in sheet',
        hypothesisId: 'H1',
        runId: 'post-fix',
        data: {'orderId': receipt.orderId},
      );
      // #endregion
      setState(() => _receipt = receipt);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo simular el pago')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _viewOrder() {
    // #region agent log
    agentDebugLog(
      location: 'payment_sandbox_sheet.dart:_viewOrder',
      message: 'closing sheet after Ver pedido',
      hypothesisId: 'H1',
      runId: 'post-fix',
      data: {'orderId': _receipt?.orderId},
    );
    // #endregion
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;
    if (receipt != null) {
      // Contenido scrolleable dentro del sheet (sin segundo Navigator.push).
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: PaymentReceiptScreen(
            receipt: receipt,
            onViewOrder: _viewOrder,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sandbox DTS',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            'Simulación — no se cobra dinero real.\nTotal: \$${widget.total.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cardController,
            decoration: const InputDecoration(
              labelText: 'Número de tarjeta',
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,
                  decoration: const InputDecoration(labelText: 'Vence'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  decoration: const InputDecoration(labelText: 'CVV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DtsPrimaryButton(
            label: 'Pagar ahora',
            isLoading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
