import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/services/auth_service.dart';
import 'package:ezer_fresh/src/data/services/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// User Profile Provider
final userProfileProvider = StreamProvider.autoDispose.family<DocumentSnapshot, String>((ref, uid) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserProfile(uid);
});
