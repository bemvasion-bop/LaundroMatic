class Payment {
  final String paymentId;
  final String orderId;
  final double amountPaid;
  final double cashReceived;
  final double changeAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? paymentDate;
  final String notes;

  Payment({
    required this.paymentId,
    required this.orderId,
    required this.amountPaid,
    required this.cashReceived,
    required this.changeAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentDate,
    required this.notes,
  });

  factory Payment.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return Payment(
      paymentId: id,
      orderId: data['order_id'] ?? '',
      amountPaid: (data['amount_paid'] ?? 0).toDouble(),
      cashReceived: (data['cash_received'] ?? 0).toDouble(),
      changeAmount: (data['change_amount'] ?? 0).toDouble(),
      paymentMethod: data['payment_method'] ?? '',
      paymentStatus: data['payment_status'] ?? 'Unpaid',
      paymentDate: data['payment_date'] != null
          ? (data['payment_date'] as dynamic).toDate()
          : null,
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_id': orderId,
      'amount_paid': amountPaid,
      'cash_received': cashReceived,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payment_date': paymentDate,
      'notes': notes,
    };
  }
}