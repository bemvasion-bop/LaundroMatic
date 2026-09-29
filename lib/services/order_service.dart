import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'orders';

  Stream<List<LaundryOrder>> getOrders() {
    return _firestore
        .collection(_collection)
        .orderBy('order_date', descending: true)
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return LaundryOrder.fromFirestore(
                  doc.id,
                  doc.data(),
                );
              },
            ).toList();
          },
        );
  }

  // Creates a PAID order, records the payment,
  // and deducts detergent/conditioner inventory
  // in one Firestore transaction.
  Future<void> createPaidOrder({
    required String customerId,
    required String serviceId,
    required double weight,
    required int packageCount,

    required String detergentOption,
    required String detergentBrand,
    String? detergentInventoryId,
    required int detergentQty,
    required double detergentFee,

    required String conditionerOption,
    required String conditionerBrand,
    String? conditionerInventoryId,
    required int conditionerQty,
    required double conditionerFee,

    required double serviceTotal,
    required double totalAmount,

    required double cashReceived,
    required double changeAmount,

    required String notes,
  }) async {
    if (cashReceived < totalAmount) {
      throw Exception(
        'Cash received is not enough to pay for this order.',
      );
    }

    final orderRef =
        _firestore.collection(_collection).doc();

    final paymentRef =
        _firestore.collection('payments').doc();

    final Map<String, int> inventoryUsage = {};

    if (detergentInventoryId != null &&
        detergentInventoryId.isNotEmpty &&
        detergentQty > 0) {
      inventoryUsage[detergentInventoryId] =
          (inventoryUsage[detergentInventoryId] ?? 0) +
          detergentQty;
    }

    if (conditionerInventoryId != null &&
        conditionerInventoryId.isNotEmpty &&
        conditionerQty > 0) {
      inventoryUsage[conditionerInventoryId] =
          (inventoryUsage[conditionerInventoryId] ?? 0) +
          conditionerQty;
    }

    await _firestore.runTransaction(
      (transaction) async {
        final Map<String, DocumentSnapshot> inventorySnapshots = {};

        // Read all required inventory first.
        for (final inventoryId in inventoryUsage.keys) {
          final inventoryRef = _firestore
              .collection('inventory')
              .doc(inventoryId);

          final inventorySnapshot =
              await transaction.get(inventoryRef);

          if (!inventorySnapshot.exists) {
            throw Exception(
              'Inventory item not found: $inventoryId',
            );
          }

          inventorySnapshots[inventoryId] =
              inventorySnapshot;
        }

        // Check stock before changing anything.
        for (final entry in inventoryUsage.entries) {
          final inventoryId = entry.key;
          final quantityUsed = entry.value;

          final snapshot =
              inventorySnapshots[inventoryId]!;

          final data =
              snapshot.data() as Map<String, dynamic>;

          final currentQuantity =
              (data['quantity'] ?? 0) as int;

          if (currentQuantity < quantityUsed) {
            final itemName =
                data['item_name'] ?? 'Inventory item';

            throw Exception(
              'Not enough stock for $itemName.',
            );
          }
        }

        // Deduct detergent/conditioner inventory
        // and create inventory transaction records.
        for (final entry in inventoryUsage.entries) {
          final inventoryId = entry.key;
          final quantityUsed = entry.value;

          final snapshot =
              inventorySnapshots[inventoryId]!;

          final data =
              snapshot.data() as Map<String, dynamic>;

          final currentQuantity =
              (data['quantity'] ?? 0) as int;

          final inventoryRef = _firestore
              .collection('inventory')
              .doc(inventoryId);

          transaction.update(inventoryRef, {
            'quantity':
                currentQuantity - quantityUsed,
            'updated_at':
                FieldValue.serverTimestamp(),
          });

          final inventoryTransactionRef =
              _firestore
                  .collection('inventory_transactions')
                  .doc();

          transaction.set(
            inventoryTransactionRef,
            {
              'inventory_id': inventoryId,
              'order_id': orderRef.id,
              'transaction_type': 'OUT',
              'quantity': quantityUsed,
              'reason':
                  'Used for laundry order',
              'transaction_date':
                  FieldValue.serverTimestamp(),
            },
          );
        }

        // Create the order as PAID.
        transaction.set(
          orderRef,
          {
            'customer_id': customerId,
            'service_id': serviceId,
            'weight': weight,
            'package_count': packageCount,

            'detergent_option':
                detergentOption,
            'detergent_brand':
                detergentBrand,
            'detergent_inventory_id':
                detergentInventoryId,
            'detergent_qty':
                detergentQty,
            'detergent_fee':
                detergentFee,

            'conditioner_option':
                conditionerOption,
            'conditioner_brand':
                conditionerBrand,
            'conditioner_inventory_id':
                conditionerInventoryId,
            'conditioner_qty':
                conditionerQty,
            'conditioner_fee':
                conditionerFee,

            'service_total': serviceTotal,
            'total_amount': totalAmount,

            'payment_status': 'Paid',
            'order_status': 'Clothes Received',

            'plastic_size': '',
            'plastic_qty': 0,

            'order_date':
                FieldValue.serverTimestamp(),
            'processing_date': null,
            'ready_date': null,
            'picked_up_date': null,

            'notes': notes,
          },
        );

        // Create the payment record.
        transaction.set(
          paymentRef,
          {
            'order_id': orderRef.id,
            'amount_paid': totalAmount,
            'cash_received': cashReceived,
            'change_amount': changeAmount,
            'payment_method': 'Cash',
            'payment_status': 'Paid',
            'payment_date':
                FieldValue.serverTimestamp(),
            'notes': '',
          },
        );
      },
    );
  }

  Future<void> updateOrder({
    required String orderId,
    required String customerId,
    required String serviceId,
    required double weight,
    required int packageCount,

    required String detergentOption,
    required String detergentBrand,
    String? detergentInventoryId,
    required int detergentQty,
    required double detergentFee,

    required String conditionerOption,
    required String conditionerBrand,
    String? conditionerInventoryId,
    required int conditionerQty,
    required double conditionerFee,

    required double serviceTotal,
    required double totalAmount,

    required String paymentStatus,
    required String orderStatus,

    required String plasticSize,
    required int plasticQty,

    required String notes,
  }) async {
    await _firestore
        .collection(_collection)
        .doc(orderId)
        .update({
      'customer_id': customerId,
      'service_id': serviceId,
      'weight': weight,
      'package_count': packageCount,

      'detergent_option': detergentOption,
      'detergent_brand': detergentBrand,
      'detergent_inventory_id':
          detergentInventoryId,
      'detergent_qty': detergentQty,
      'detergent_fee': detergentFee,

      'conditioner_option':
          conditionerOption,
      'conditioner_brand':
          conditionerBrand,
      'conditioner_inventory_id':
          conditionerInventoryId,
      'conditioner_qty': conditionerQty,
      'conditioner_fee': conditionerFee,

      'service_total': serviceTotal,
      'total_amount': totalAmount,

      'payment_status': paymentStatus,
      'order_status': orderStatus,

      'plastic_size': plasticSize,
      'plastic_qty': plasticQty,

      'notes': notes,
    });
  }

  // Moves the order from Clothes Received
  // to Processing.
  //
  // Detergent and conditioner inventory are
  // already deducted when the order is created.
  Future<void> startProcessing(
    LaundryOrder order,
  ) async {
    final orderRef =
        _firestore.collection(_collection).doc(
              order.orderId,
            );

    await _firestore.runTransaction(
      (transaction) async {
        final orderSnapshot =
            await transaction.get(orderRef);

        if (!orderSnapshot.exists) {
          throw Exception('Order not found.');
        }

        final orderData =
            orderSnapshot.data()
                as Map<String, dynamic>;

        final currentStatus =
            orderData['order_status'] ??
                'Clothes Received';

        final currentPaymentStatus =
            orderData['payment_status'] ??
                'Unpaid';

        if (currentStatus != 'Clothes Received') {
          throw Exception(
            'This order has already been processed.',
          );
        }

        if (currentPaymentStatus != 'Paid') {
          throw Exception(
            'Full payment is required before processing.',
          );
        }

        transaction.update(
          orderRef,
          {
            'order_status': 'Processing',
            'processing_date': FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  Future<void> markReadyForPickup({
      required LaundryOrder order,
      required String plasticInventoryId,
      required int plasticQuantity,
    }) async {
      if (plasticQuantity <= 0) {
        throw Exception(
          'Please enter the quantity of plastic packaging used.',
        );
      }

      final orderRef = _firestore
          .collection(_collection)
          .doc(order.orderId);

      final inventoryRef = _firestore
          .collection('inventory')
          .doc(plasticInventoryId);

      final inventoryTransactionRef = _firestore
          .collection('inventory_transactions')
          .doc();

      await _firestore.runTransaction(
        (transaction) async {
          // Read the order first.
          final orderSnapshot =
              await transaction.get(orderRef);

          if (!orderSnapshot.exists) {
            throw Exception('Order not found.');
          }

          final orderData =
              orderSnapshot.data()
                  as Map<String, dynamic>;

          final currentStatus =
              orderData['order_status'] ??
                  'Clothes Received';

          // The order must currently be Processing.
          if (currentStatus != 'Processing') {
            throw Exception(
              'Only orders that are Processing can be marked Ready for Pickup.',
            );
          }

          // Prevent the same order from being processed twice.
          final existingPlasticQty =
              (orderData['plastic_qty'] ?? 0) as int;

          if (existingPlasticQty > 0) {
            throw Exception(
              'Plastic packaging has already been recorded for this order.',
            );
          }

          // Read the plastic inventory item.
          final inventorySnapshot =
              await transaction.get(inventoryRef);

          if (!inventorySnapshot.exists) {
            throw Exception(
              'Plastic packaging inventory item not found.',
            );
          }

          final inventoryData =
              inventorySnapshot.data()
                  as Map<String, dynamic>;

          final currentQuantity =
              (inventoryData['quantity'] ?? 0) as int;

          final itemName =
              inventoryData['item_name'] ??
                  'Plastic packaging';

          final itemSize =
              inventoryData['size'] ?? '';

          // Check available stock.
          if (currentQuantity < plasticQuantity) {
            throw Exception(
              'Not enough stock for $itemName. '
              'Available: $currentQuantity.',
            );
          }

          // Deduct plastic inventory.
          transaction.update(
            inventoryRef,
            {
              'quantity':
                  currentQuantity - plasticQuantity,
              'updated_at':
                  FieldValue.serverTimestamp(),
            },
          );

          // Record the inventory movement.
          transaction.set(
            inventoryTransactionRef,
            {
              'inventory_id': plasticInventoryId,
              'order_id': order.orderId,
              'transaction_type': 'OUT',
              'quantity': plasticQuantity,
              'reason':
                  'Used for laundry order packaging',
              'transaction_date':
                  FieldValue.serverTimestamp(),
            },
          );

          // Update the order.
          transaction.update(
            orderRef,
            {
              'plastic_size': itemSize,
              'plastic_qty': plasticQuantity,
              'order_status': 'Ready for Pickup',
              'ready_date':
                  FieldValue.serverTimestamp(),
            },
          );
        },
      );
    }

  Future<void> markPickedUp(String orderId) async {
    final orderRef = _firestore
        .collection(_collection)
        .doc(orderId);

    await orderRef.update({
      'order_status': 'Picked Up',
      'picked_up_date': FieldValue.serverTimestamp(),
    });
  }



  Future<void> markOrderAsPaid(
    String orderId,
  ) async {
    await _firestore
        .collection(_collection)
        .doc(orderId)
        .update({
      'payment_status': 'Paid',
    });
  }

  Future<void> deleteOrder(
    String orderId,
  ) async {
    await _firestore
        .collection(_collection)
        .doc(orderId)
        .delete();
  }
}