import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/debug/agent_debug_log.dart';
import '../../../../core/di/repository_providers.dart';
import '../../domain/entities/payment_receipt.dart';
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
  final dest = isService
      ? '/service-tracking/$orderId'
      : '/tracking/$orderId';

  if (!isSandboxPaymentMethod(method)) {
    context.go(dest);
    return;
  }

  final paid = await PaymentSandboxSheet.show(
    context,
    total: total,
    onPay: (last4) async {
      final data = await ref
          .read(ordersRemoteDataSourceProvider)
          .sandboxPay(orderId: orderId, cardLast4: last4);
      // #region agent log
      agentDebugLog(
        location: 'checkout_payment_helper.dart:onPay',
        message: 'sandbox pay ok, return receipt for inline sheet',
        hypothesisId: 'H1',
        runId: 'post-fix',
        data: {'orderId': orderId},
      );
      // #endregion
      return PaymentReceipt.fromJson(data);
    },
  );

  if (!context.mounted) return;
  // #region agent log
  agentDebugLog(
    location: 'checkout_payment_helper.dart:afterSandbox',
    message: 'sheet closed; go tracking if paid',
    hypothesisId: 'H1',
    runId: 'post-fix',
    data: {'paid': paid, 'dest': dest},
  );
  // #endregion
  // El Future del sheet completa tras didComplete del modal: seguro hacer go.
  if (paid == true) {
    context.go(dest);
  }
}
