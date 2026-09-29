import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/stock_movement.dart';

class StockMovementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'stock_movements';

  // Get all stock movements
  Stream<List<StockMovement>> getStockMovements() {
    return _firestore
        .collection(_collection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StockMovement.fromFirestore(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }

  // Get movements for a specific inventory item
  Stream<List<StockMovement>> getMovementsForInventory(
    String inventoryId,
  ) {
    return _firestore
        .collection(_collection)
        .where(
          'inventory_id',
          isEqualTo: inventoryId,
        )
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StockMovement.fromFirestore(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }

  // Record a stock movement
  Future<void> addStockMovement({
    required String inventoryId,
    required String itemName,
    required String movementType,
    required int quantity,
    required int previousQuantity,
    required int newQuantity,
    required String reason,
    String referenceId = '',
  }) async {
    await _firestore.collection(_collection).add({
      'inventory_id': inventoryId,
      'item_name': itemName,
      'movement_type': movementType,
      'quantity': quantity,
      'previous_quantity': previousQuantity,
      'new_quantity': newQuantity,
      'reason': reason,
      'reference_id': referenceId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}