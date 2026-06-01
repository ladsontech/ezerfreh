import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
      });
});

final customerOrdersProvider = StreamProvider.family<List<OrderModel>, String>((
  ref,
  userId,
) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
      );
});

final activeDeliveryOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  const activeStatuses = ['Processing', 'Ready for Pickup', 'Out for Delivery'];

  return FirebaseFirestore.instance
      .collection('orders')
      .where('status', whereIn: activeStatuses)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
      );
});
