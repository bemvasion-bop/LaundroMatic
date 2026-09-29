import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'notifications';

  static const String _serviceId = 'service_hj3zraw';
  static const String _templateId = 'template_6d2nnsz';

  static const String _publicKey = 'UWGDt_OoBudrmFX-e';

  Future<void> sendReadyForPickupEmail({
    required String toEmail,
    required String customerName,
    required String customerId,
    required String orderId,
    required String serviceName,
    required double weight,
    required double totalAmount,
    required String orderStatus,
  }) async {
    if (toEmail.trim().isEmpty) {
      throw Exception('Customer does not have an email address.');
    }

    if (orderStatus != 'Ready for Pickup') {
      throw Exception(
        'Email can only be sent when the order is Ready for Pickup.',
      );
    }

    final now = DateTime.now();

    // Check the most recent Ready for Pickup notification.
    final recentNotifications = await _firestore
        .collection(_collection)
        .where('order_id', isEqualTo: orderId)
        .where(
          'notification_type',
          isEqualTo: 'Ready for Pickup',
        )
        .orderBy('sent_at', descending: true)
        .limit(1)
        .get();

    if (recentNotifications.docs.isNotEmpty) {
      final data = recentNotifications.docs.first.data();
      final timestamp = data['sent_at'];

      if (timestamp != null) {
        final lastSentAt = (timestamp as Timestamp).toDate();
        final difference = now.difference(lastSentAt);

        if (difference.inSeconds < 10) {
          final remaining = 10 - difference.inSeconds;

          throw Exception(
            'Please wait $remaining seconds before sending again.',
          );
        }
      }
    }

    // Send the email through the EmailJS REST API.
    final response = await http.post(
      Uri.parse(
        'https://api.emailjs.com/api/v1.0/email/send',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'to_email': toEmail.trim(),
          'customer_name': customerName,
          'order_id': orderId.length >= 6
              ? orderId.substring(0, 6)
              : orderId,
          'service_name': serviceName,
          'weight': weight.toString(),
          'total_amount': totalAmount.toStringAsFixed(2),
          'order_status': orderStatus,
        },
      }),
    );

    // Show the actual EmailJS response if something goes wrong.
    if (response.statusCode != 200) {
      throw Exception(
        'EmailJS error ${response.statusCode}: ${response.body}',
      );
    }

    // Record the successful notification in Firestore.
    await _firestore.collection(_collection).add({
      'order_id': orderId,
      'customer_id': customerId,
      'email': toEmail.trim(),
      'notification_type': 'Ready for Pickup',
      'sent_at': FieldValue.serverTimestamp(),
      'status': 'Sent',
    });
  }
}