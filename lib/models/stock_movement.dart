import 'package:cloud_firestore/cloud_firestore.dart';

class StockMovement {
  final String movementId;
  final String inventoryId;
  final String itemName;
  final String movementType;
  final int quantity;
  final int previousQuantity;
  final int newQuantity;
  final String reason;
  final String referenceId;
  final DateTime? createdAt;

  StockMovement({
    required this.movementId,
    required this.inventoryId,
    required this.itemName,
    required this.movementType,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    required this.reason,
    required this.referenceId,
    this.createdAt,
  });

  factory StockMovement.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return StockMovement(
      movementId: documentId,
      inventoryId: data['inventory_id'] ?? '',
      itemName: data['item_name'] ?? '',
      movementType: data['movement_type'] ?? '',
      quantity: (data['quantity'] ?? 0).toInt(),
      previousQuantity: (data['previous_quantity'] ?? 0).toInt(),
      newQuantity: (data['new_quantity'] ?? 0).toInt(),
      reason: data['reason'] ?? '',
      referenceId: data['reference_id'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inventory_id': inventoryId,
      'item_name': itemName,
      'movement_type': movementType,
      'quantity': quantity,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'reason': reason,
      'reference_id': referenceId,
      'created_at': createdAt,
    };
  }
}