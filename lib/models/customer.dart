import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String customerId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final DateTime? createdAt;

  Customer ({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.createdAt,
  });

  //Convert Firestore document -> Customer object
  factory Customer.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return Customer(
      customerId: documentId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  //Convert Customer object -> Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': createdAt
    };
  }
}