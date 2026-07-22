import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<DocumentSnapshot> getUserProfileDoc(String uid, {bool cacheFirst = true}) async {
    if (cacheFirst) {
      try {
        final cachedDoc = await _firestore.collection('users').doc(uid).get(const GetOptions(source: Source.cache));
        if (cachedDoc.exists) return cachedDoc;
      } catch (_) {
        // Fallback to server if cache missed or failed
      }
    }
    return _firestore.collection('users').doc(uid).get(const GetOptions(source: Source.serverAndCache));
  }

  Future<void> setUserProfile(String uid, Map<String, dynamic> data) {
    return _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }
}

