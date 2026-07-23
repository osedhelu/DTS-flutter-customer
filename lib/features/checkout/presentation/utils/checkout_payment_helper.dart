import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/debug/agent_debug_log.dart';
import '../../../../core/di/repository_providers.dart';
import '../../domain/entities/payment_receipt.dart';
import '../screens/payment_receipt_screen.dart';
import '../widgets/payment_sandbox_sheet.dart';

bool isSandboxPaymentMethod(Map<String, dynamic>? method) {
  if (method == null) return false;
  if (method['id'] == 0) return true;
  return method['method_type']?.toString() == 'sandbox';
}

Map<String, dynamic>? selectedPaymentMethod(
  List<Map<String, dynamic>> methods,
  int? selectedId,
) {
  for (final method in methods) {
    if (method['id'] == selectedId) return method;
  }
  return null;
}

Future<void> completeOrderWithOptionalSandbox({
  required BuildContext context,
  required WidgetRef ref,
  required int orderId,
  required double total,
  required List<Map<String, dynamic>> paymentMethods,
  required int? selectedPaymentMethodId,
  required bool isService,
}) async {
  final method = selectedPaymentMethod(paymentMethods, selectedPaymentMethodId);
  if (!isSandboxPaymentMethod(method)) {
    context.go(
      isService
          ? '/service-tracking/$orderId'
          : '/tracking/$orderId',
    );
    return;
  }

  final paid = await PaymentSandboxSheet.show(
    context,
    total: total,
    onPay: (last4) async {
      final data = await ref
          .read(ordersRemoteDataSourceProvider)
          .sandboxPay(orderId: orderId, cardLast4: last4);
      if (!context.mounted) return;
      final receipt = PaymentReceipt.fromJson(data);
      // #region agent log
      agentDebugLog(
        location: 'checkout_payment_helper.dart:onPay',
        message: 'pushing PaymentReceipt via Navigator',
        hypothesisId: 'H2',
        data: {'orderId': orderId, 'canPop': Navigator.of(context).canPop()},
      );
      // #endregion
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PaymentReceiptScreen(receipt: receipt),
        ),
      );
      // #region agent log
      agentDebugLog(
        location: 'checkout_payment_helper.dart:afterReceipt',
        message: 'PaymentReceipt pop completed',
        hypothesisId: 'H2',
        data: {'orderId': orderId},
      );
      // #endregion
    },
  );

  if (!context.mounted) return;
  final dest = isService
      ? '/service-tracking/$orderId'
      : '/tracking/$orderId';
  // #region agent log
  agentDebugLog(
    location: 'checkout_payment_helper.dart:afterSandbox',
    message: 'context.go after sandbox sheet',
    hypothesisId: 'H1',
    data: {'paid': paid, 'dest': dest},
  );
  // #endregion
  context.go(dest);
}
