import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inventory.dart';
import '../models/inventory_transactions.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'inventory';

  Stream<List<InventoryItem>> getInventory() {
    return _firestore
        .collection(_collection)  
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return InventoryItem.fromFirestore(
                  doc.id,
                  doc.data(),
                );
              },
            ).toList();
          },
        );
  }

  Stream<List<InventoryTransaction>> getInventoryTransactions() {
    return _firestore
        .collection('inventory_transactions')
        .orderBy('transaction_date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return InventoryTransaction.fromFirestore(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }

  
  Stream<List<InventoryItem>> getDetergents() {
    return _firestore
        .collection(_collection)
        .where('item_type', isEqualTo: 'Detergent')
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return InventoryItem.fromFirestore(
                  doc.id,
                  doc.data(),
                );
              },
            ).toList();
          },
        );
  }

  Stream<List<InventoryItem>> getFabricConditioners() {
    return _firestore
        .collection(_collection)
        .where(
          'item_type',
          isEqualTo: 'Fabric Conditioner',
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return InventoryItem.fromFirestore(
                  doc.id,
                  doc.data(),
                );
              },
            ).toList();
          },
        );
  }

  Stream<List<InventoryItem>> getPlasticBags() {
    return _firestore
        .collection(_collection)
        .where(
          'item_type',
          isEqualTo: 'Plastic Bag',
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return InventoryItem.fromFirestore(
                  doc.id,
                  doc.data(),
                );
              },
            ).toList();
          },
        );
  }

  Future<void> addInventoryItem({
    required String itemName,
    required String brand,
    required String scent,
    required String itemType,
    required String size,
    required int quantity,
    required String unit,
    required double pricePerUnit,
    required int minimumStock,
    required String imageUrl,
  }) async {
    final String status = _getStockStatus(
      quantity,
      minimumStock,
    );

    await _firestore.collection(_collection).add({
      'item_name': itemName,
      'brand': brand,
      'scent': scent,
      'item_type': itemType,
      'size': size,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'minimum_stock': minimumStock,
      'image_url': imageUrl,
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateInventoryItem({
    required String inventoryId,
    required String itemName,
    required String brand,
    required String scent,
    required String itemType,
    required String size,
    required int quantity,
    required String unit,
    required double pricePerUnit,
    required int minimumStock,
    required String imageUrl,
  }) async {
    final String status = _getStockStatus(
      quantity,
      minimumStock,
    );

    await _firestore
        .collection(_collection)
        .doc(inventoryId)
        .update({
      'item_name': itemName,
      'brand': brand,
      'scent': scent,
      'item_type': itemType,
      'size': size,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'minimum_stock': minimumStock,
      'image_url': imageUrl,
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteInventoryItem(String inventoryId) async {
    await _firestore
        .collection(_collection)
        .doc(inventoryId)
        .delete();
  }

  Future<void> addStock({
    required String inventoryId,
    required int quantityToAdd,
  }) async {
    if (quantityToAdd <= 0) {
      throw Exception('Quantity must be greater than zero.');
    }

    final inventoryRef =
        _firestore.collection(_collection).doc(inventoryId);

    final inventorySnapshot = await inventoryRef.get();

    if (!inventorySnapshot.exists) {
      throw Exception('Inventory item not found.');
    }

    final data = inventorySnapshot.data()!;

    final int currentQuantity =
        (data['quantity'] ?? 0).toInt();

    final int minimumStock =
        (data['minimum_stock'] ?? 0).toInt();

    final int newQuantity =
        currentQuantity + quantityToAdd;

    final String newStatus =
        _getStockStatus(
          newQuantity,
          minimumStock,
        );

    // Update inventory quantity and status
    await inventoryRef.update({
      'quantity': newQuantity,
      'status': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Record stock IN transaction
    await _firestore.collection('inventory_transactions').add({
      'inventory_id': inventoryId,
      'order_id': null,
      'quantity': quantityToAdd,
      'reason': 'Manual stock addition',
      'transaction_date': FieldValue.serverTimestamp(),
      'transaction_type': 'IN',
    });
  }

  String _getStockStatus(
    int quantity,
    int minimumStock,
  ) {
    if (quantity == 0) {
      return 'Out of Stock';
    } else if (quantity <= minimumStock) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }
}