import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'payments';

  Stream<List<Payment>> getPayments() {
    return _firestore
        .collection(_collection)
        .orderBy('payment_date', descending: true)
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return Payment.fromFirestore(
                  doc.id,
                  doc.data(),
                );
              },
            ).toList();
          },
        );
  }

  Stream<Payment?> getPaymentByOrderId(String orderId) {
    return _firestore
        .collection(_collection)
        .where(
          'order_id',
          isEqualTo: orderId,
        )
        .limit(1)
        .snapshots()
        .map(
          (snapshot) {
            if (snapshot.docs.isEmpty) {
              return null;
            }

            final doc = snapshot.docs.first;

            return Payment.fromFirestore(
              doc.id,
              doc.data(),
            );
          },
        );
  }

  Future<void> addPayment({
    required String orderId,
    required double amountPaid,
    required double cashReceived,
    required double changeAmount,
    required String paymentMethod,
    required String paymentStatus,
    String notes = '',
  }) async {
    final paymentRef =
        _firestore.collection(_collection).doc();

    final payment = Payment(
      paymentId: paymentRef.id,
      orderId: orderId,
      amountPaid: amountPaid,
      cashReceived: cashReceived,
      changeAmount: changeAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      paymentDate: DateTime.now(),
      notes: notes,
    );

    await paymentRef.set(
      payment.toFirestore(),
    );
  }

  Future<void> updatePayment({
    required String paymentId,
    required String orderId,
    required double amountPaid,
    required double cashReceived,
    required double changeAmount,
    required String paymentMethod,
    required String paymentStatus,
    required String notes,
  }) async {
    await _firestore
        .collection(_collection)
        .doc(paymentId)
        .update({
      'order_id': orderId,
      'amount_paid': amountPaid,
      'cash_received': cashReceived,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'notes': notes,
    });
  }

  Future<void> deletePayment(String paymentId) async {
    await _firestore
        .collection(_collection)
        .doc(paymentId)
        .delete();
  }
}