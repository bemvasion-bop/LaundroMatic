import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String inventoryId;
  final String itemName;
  final String brand;
  final String scent;
  final String itemType;
  final String size;
  final int quantity;
  final String unit;
  final double pricePerUnit;
  final int minimumStock;
  final String imageUrl;
  final String status;
  final DateTime? updatedAt;

  InventoryItem({
    required this.inventoryId,
    required this.itemName,
    required this.brand,
    required this.scent,
    required this.itemType,
    required this.size,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.minimumStock,
    required this.imageUrl,
    required this.status,
    this.updatedAt,
  });

  factory InventoryItem.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return InventoryItem(
      inventoryId: documentId,
      itemName: data['item_name'] ?? '',
      brand: data['brand'] ?? '',
      scent: data['scent'] ?? '',
      itemType: data['item_type'] ?? '',
      size: data['size'] ?? '',
      quantity: (data['quantity'] ?? 0).toInt(),
      unit: data['unit'] ?? '',
      pricePerUnit: (data['price_per_unit'] ?? 0).toDouble(),
      minimumStock: (data['minimum_stock'] ?? 0).toInt(),
      imageUrl: data['image_url'] ?? '',
      status: data['status'] ?? 'In Stock',
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
      'updated_at': updatedAt,
    };
  }
}