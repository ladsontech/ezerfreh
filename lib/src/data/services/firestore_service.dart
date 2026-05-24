import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<void> setUserProfile(String uid, Map<String, dynamic> data) {
    return _firestore.collection('users').doc(uid).set(data);
  }
}
