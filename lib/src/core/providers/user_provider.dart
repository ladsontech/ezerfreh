import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AppUser(
        id: doc.id,
        name: data['name'] ?? 'Guest',
        email: data['email'] ?? 'No email',
        role: (data['role'] as String?)?.trim().toLowerCase() ?? 'customer',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  });
});

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });
}
