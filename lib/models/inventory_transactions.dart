import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryTransaction {
  final String transactionId;
  final String inventoryId;
  final String? orderId;
  final int quantity;
  final String reason;
  final DateTime? transactionDate;
  final String transactionType;

  InventoryTransaction({
    required this.transactionId,
    required this.inventoryId,
    this.orderId,
    required this.quantity,
    required this.reason,
    this.transactionDate,
    required this.transactionType,
  });

  factory InventoryTransaction.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return InventoryTransaction(
      transactionId: documentId,
      inventoryId: data['inventory_id'] ?? '',
      orderId: data['order_id'],
      quantity: (data['quantity'] ?? 0).toInt(),
      reason: data['reason'] ?? '',
      transactionDate:
          (data['transaction_date'] as Timestamp?)?.toDate(),
      transactionType: data['transaction_type'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inventory_id': inventoryId,
      'order_id': orderId,
      'quantity': quantity,
      'reason': reason,
      'transaction_date': transactionDate,
      'transaction_type': transactionType,
    };
  }
}