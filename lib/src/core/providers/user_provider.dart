import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AppUser(
        id: doc.id,
        name: _stringField(data['name'], fallback: 'Guest'),
        email: _stringField(data['email'], fallback: 'No email'),
        role: _stringField(data['role'], fallback: 'customer').toLowerCase(),
        createdAt: parseUserCreatedAt(data['createdAt']),
      );
    }).toList();
  });
});

String _stringField(Object? value, {required String fallback}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

DateTime? parseUserCreatedAt(Object? value) {
  return switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime dateTime => dateTime,
    String text => DateTime.tryParse(text),
    _ => null,
  };
}

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
