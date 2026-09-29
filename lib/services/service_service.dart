import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service.dart';

class ServiceService {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'services';

  //get all services
  Stream<List<LaundryService>> getServices() {
    return _firestore
      .collection(_collection)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map(
        (snapshot) {
          return snapshot.docs.map(
            (doc) {
            return LaundryService.fromFirestore(
              doc.id,
              doc.data(),
            );
            },
          ).toList();
        }
      );
  }

  // add a new service
  Future <void> addService({
    required String serviceName,
    required double maxWeight,
    required double bundlePrice,
    required String description,
    required String status,
  }) async {
    await _firestore.collection(_collection).add({
      'service_name': serviceName,
      'max_weight': maxWeight,
      'bundle_price': bundlePrice,
      'description': description,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // update an existing service
  Future <void> updateService({
    required String serviceId,
    required String serviceName,
    required double maxWeight,
    required double bundlePrice,
    required String description,
    required String status,
  }) async {
    await _firestore.collection(_collection).doc(serviceId).update({
      'service_name': serviceName,
      'max_weight': maxWeight,
      'bundle_price': bundlePrice,
      'description': description,
      'status': status,
    });
  }

  // Delete a service
  Future<void> deleteService(String serviceId) async {
    await _firestore
        .collection(_collection)
        .doc(serviceId)
        .delete();
  }
}