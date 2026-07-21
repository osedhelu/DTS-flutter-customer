class PaymentReceipt {
  const PaymentReceipt({
    required this.orderId,
    required this.paymentStatus,
    required this.paymentReference,
    required this.paidAt,
    required this.subtotal,
    required this.discountAmount,
    required this.totalPaid,
    required this.platformCommissionRate,
    required this.platformCommission,
    required this.merchantNet,
    required this.paymentMethodLabel,
  });

  final int orderId;
  final String paymentStatus;
  final String paymentReference;
  final DateTime paidAt;
  final double subtotal;
  final double discountAmount;
  final double totalPaid;
  final double platformCommissionRate;
  final double platformCommission;
  final double merchantNet;
  final String paymentMethodLabel;

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) {
    return PaymentReceipt(
      orderId: json['order_id'] as int,
      paymentStatus: json['payment_status'] as String,
      paymentReference: json['payment_reference'] as String,
      paidAt: DateTime.parse(json['paid_at'] as String),
      subtotal: double.parse(json['subtotal'].toString()),
      discountAmount: double.parse(json['discount_amount'].toString()),
      totalPaid: double.parse(json['total_paid'].toString()),
      platformCommissionRate:
          double.parse(json['platform_commission_rate'].toString()),
      platformCommission:
          double.parse(json['platform_commission'].toString()),
      merchantNet: double.parse(json['merchant_net'].toString()),
      paymentMethodLabel: json['payment_method_label'] as String? ?? 'Sandbox DTS',
    );
  }
}
