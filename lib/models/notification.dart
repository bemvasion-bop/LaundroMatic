class NotificationRecord {
  final String notificationId;
  final String orderId;
  final String customerId;
  final String email;
  final String notificationType;
  final DateTime? sentAt;
  final String status;

  NotificationRecord({
    required this.notificationId,
    required this.orderId,
    required this.customerId,
    required this.email,
    required this.notificationType,
    this.sentAt,
    required this.status,
  });

  factory NotificationRecord.fromFirestore(
      String id,
      Map<String, dynamic> data,
  ) {
    return NotificationRecord(
      notificationId: id,
      orderId: data['order_id'] ?? '',
      customerId: data ['customer_id'] ?? '',
      email: data ['email'] ?? '',
      notificationType: data ['notification_type'] ?? '',
      sentAt: data ['sent_at'] != null 
          ? (data['sent_at'] as dynamic).toDate()
          : null,
      status: data ['status'] ?? '',

    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_id': orderId,
      'customer_id' : customerId,
      'email' : email,
      'notification_type' : notificationType,
      'sent_at' : sentAt,
      'status' : status,
    };
  }
} 