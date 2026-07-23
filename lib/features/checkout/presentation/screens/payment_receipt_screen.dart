import 'package:flutter/material.dart';

import '../../../../core/debug/agent_debug_log.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/payment_receipt.dart';

class PaymentReceiptScreen extends StatelessWidget {
  const PaymentReceiptScreen({super.key, required this.receipt});

  final PaymentReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recibo de pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 72),
          const SizedBox(height: 12),
          Text(
            'Pago confirmado',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            'Pedido #${receipt.orderId}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _Row(label: 'Método', value: receipt.paymentMethodLabel),
          _Row(label: 'Referencia', value: receipt.paymentReference),
          _Row(
            label: 'Fecha',
            value: receipt.paidAt.toLocal().toString(),
          ),
          const Divider(height: 32),
          _Row(label: 'Subtotal', value: '\$${receipt.subtotal.toStringAsFixed(2)}'),
          if (receipt.discountAmount > 0)
            _Row(
              label: 'Descuento',
              value: '-\$${receipt.discountAmount.toStringAsFixed(2)}',
            ),
          _Row(
            label: 'Total pagado',
            value: '\$${receipt.totalPaid.toStringAsFixed(2)}',
            emphasized: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Comisión plataforma (${(receipt.platformCommissionRate * 100).toStringAsFixed(0)}%): '
            '\$${receipt.platformCommission.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Neto comercio (estimado): \$${receipt.merchantNet.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          DtsPrimaryButton(
            label: 'Ver pedido',
            onPressed: () {
              // #region agent log
              final nav = Navigator.of(context);
              agentDebugLog(
                location: 'payment_receipt_screen.dart:Ver pedido',
                message: 'about to popUntil isFirst',
                hypothesisId: 'H1',
                data: {
                  'canPop': nav.canPop(),
                  'orderId': receipt.orderId,
                },
              );
              // #endregion
              nav.popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
