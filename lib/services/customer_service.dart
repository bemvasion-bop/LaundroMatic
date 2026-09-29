import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';

class CustomerService {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final String _collection = 'customers';

    //get all customers
    Stream<List<Customer>> getCustomers() {
      return _firestore
        .collection(_collection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
              return Customer.fromFirestore(
                doc.id,
                doc.data(),
              );
              },
            ).toList();
          }
        );
    }

    Future <void> addCustomer({
      required String name,
      required String phone,
      required String email,
      required String address,
    }) async {
      await _firestore.collection(_collection).add({
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    // update an existing cusotmer
    Future <void> updateCustomer({
      required String customerId,
      required String name,
      required String phone,
      required String email,
      required String address,
    }) async {
      await _firestore.collection(_collection).doc(customerId).update({
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
      });
    }


      // delete a customer
    Future<void> deleteCustomer (String customerId) async {
      await _firestore.collection(_collection).doc(customerId).delete();
    }
}