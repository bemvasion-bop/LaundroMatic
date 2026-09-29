import 'package:cloud_firestore/cloud_firestore.dart';

class LaundryOrder {
final String orderId;
  final String customerId;
  final String serviceId;
  final double weight;
  final int packageCount;

  final String detergentOption;
  final String detergentBrand;
  final String? detergentInventoryId;
  final int detergentQty;
  final double detergentFee;

  final String conditionerOption;
  final String conditionerBrand;
  final String? conditionerInventoryId;
  final int conditionerQty;
  final double conditionerFee;

  final double serviceTotal;
  final double totalAmount;

  final String paymentStatus;
  final String orderStatus;

  final String plasticSize;
  final int plasticQty;

  final DateTime? orderDate;
  final DateTime? processingDate;
  final DateTime? readyDate;
  final DateTime? pickedUpDate;
  final String notes;

  LaundryOrder({
    required this.orderId,
    required this.customerId,
    required this.serviceId,
    required this.weight,
    required this.packageCount,
    required this.detergentOption,
    required this.detergentBrand,
    this.detergentInventoryId,
    required this.detergentQty,
    required this.detergentFee,
    required this.conditionerOption,
    required this.conditionerBrand,
    this.conditionerInventoryId,
    required this.conditionerQty,
    required this.conditionerFee,
    required this.serviceTotal,
    required this.totalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.plasticSize,
    required this.plasticQty,
    this.orderDate,
    this.processingDate,
    this.readyDate,
    this.pickedUpDate,
    required this.notes,
  });

  factory LaundryOrder.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return LaundryOrder(
      orderId: documentId,
      customerId: data['customer_id'] ?? '',
      serviceId: data['service_id'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      packageCount: data['package_count'] ?? 0,

      detergentOption: data['detergent_option'] ?? 'Own Detergent',
      detergentBrand: data['detergent_brand'] ?? '',
      detergentInventoryId: data['detergent_inventory_id'],
      detergentQty: data['detergent_qty'] ?? 0,
      detergentFee: (data['detergent_fee'] ?? 0).toDouble(),

      conditionerOption:
          data['conditioner_option'] ?? 'Own Fabric Conditioner',
      conditionerBrand: data['conditioner_brand'] ?? '',
      conditionerInventoryId: data['conditioner_inventory_id'],
      conditionerQty: data['conditioner_qty'] ?? 0,
      conditionerFee: (data['conditioner_fee'] ?? 0).toDouble(),

      serviceTotal: (data['service_total'] ?? 0).toDouble(),
      totalAmount: (data['total_amount'] ?? 0).toDouble(),

      paymentStatus: data['payment_status'] ?? 'Unpaid',
      orderStatus: data['order_status'] ?? 'Clothes Received',

      plasticSize: data['plastic_size'] ?? '',
      plasticQty: data['plastic_qty'] ?? 0,

      orderDate: (data['order_date'] as Timestamp?)?.toDate(),
      processingDate:
          (data['processing_date'] as Timestamp?)?.toDate(),
      readyDate: (data['ready_date'] as Timestamp?)?.toDate(),
      pickedUpDate:
          (data['picked_up_date'] as Timestamp?)?.toDate(),

      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customer_id': customerId,
      'service_id': serviceId,
      'weight': weight,
      'package_count': packageCount,

      'detergent_option': detergentOption,
      'detergent_brand': detergentBrand,
      'detergent_inventory_id': detergentInventoryId,
      'detergent_qty': detergentQty,
      'detergent_fee': detergentFee,

      'conditioner_option': conditionerOption,
      'conditioner_brand': conditionerBrand,
      'conditioner_inventory_id': conditionerInventoryId,
      'conditioner_qty': conditionerQty,
      'conditioner_fee': conditionerFee,

      'service_total': serviceTotal,
      'total_amount': totalAmount,

      'payment_status': paymentStatus,
      'order_status': orderStatus,

      'plastic_size': plasticSize,
      'plastic_qty': plasticQty,

      'order_date': orderDate,
      'processing_date': processingDate,
      'ready_date': readyDate,
      'picked_up_date': pickedUpDate,


      'notes': notes,
    };
  }

}