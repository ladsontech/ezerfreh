import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/services/local_cache_service.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalCacheService _cacheService = LocalCacheService();

  Stream<DocumentSnapshot> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<DocumentSnapshot> getUserProfileDoc(String uid, {bool cacheFirst = true}) async {
    if (cacheFirst) {
      try {
        final cachedDoc = await _firestore
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (cachedDoc.exists) return cachedDoc;
      } catch (_) {
        // Fallback to server
      }
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.serverAndCache));
  }

  Future<Map<String, dynamic>?> getCachedUserProfileData(String uid) async {
    try {
      final cacheKey = 'user_profile_$uid';
      final cached = await _cacheService.get(cacheKey);
      if (cached is Map<String, dynamic>) {
        return cached;
      }

      // Fetch from Firestore
      final doc = await getUserProfileDoc(uid, cacheFirst: true);
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        await _cacheService.save(cacheKey, data, ttlMinutes: 1440); // 24h
        return data;
      }
    } catch (e) {
      debugPrint('Error loading cached user profile: $e');
    }
    return null;
  }

  Future<void> setUserProfile(String uid, Map<String, dynamic> data) async {
    final cacheKey = 'user_profile_$uid';
    await _cacheService.save(cacheKey, data, ttlMinutes: 1440);
    return _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }
}
