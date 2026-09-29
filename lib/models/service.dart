import 'package:cloud_firestore/cloud_firestore.dart';

class LaundryService {
  final String serviceId;
  final String serviceName;
  final double maxWeight;
  final double bundlePrice;
  final String description;
  final String status;
  final DateTime? createdAt;

  LaundryService({
    required this.serviceId,
    required this.serviceName,
    required this.maxWeight,
    required this.bundlePrice,
    required this.description,
    required this.status,
    this.createdAt,
  });


  // Convert Firestore document → LaundryService object
  factory LaundryService.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return LaundryService(
      serviceId: documentId,
      serviceName: data['service_name'] ?? '',
      maxWeight: (data['max_weight'] ?? 0).toDouble(),
      bundlePrice: (data['bundle_price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      status: data['status'] ?? 'Active',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  // Convert LaundryService object → Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'service_name': serviceName,
      'max_weight': maxWeight,
      'bundle_price': bundlePrice,
      'description': description,
      'status': status,
      'created_at': createdAt,
    };
  }
}
