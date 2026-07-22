import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Stream<List<OrderModel>> _ordersFromQuery(Query query) {
  return query.snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
      );
}

final adminOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return _ordersFromQuery(
    FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(50),
  );
});

/// All orders for riders — real-time feed of every order in the system.
final riderOrdersProvider = adminOrdersProvider;

final customerOrdersProvider = StreamProvider.family<List<OrderModel>, String>((
  ref,
  userId,
) {
  return _ordersFromQuery(
    FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50),
  );
});

final activeDeliveryOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  const activeStatuses = [
    'Processing',
    'Ready for Pickup',
    'Assigned',
    'Picked Up',
    'On the Way',
    'Out for Delivery',
    'Arrived',
  ];

  return _ordersFromQuery(
    FirebaseFirestore.instance
        .collection('orders')
        .where('status', whereIn: activeStatuses)
        .orderBy('createdAt', descending: true),
  );
});

final riderHistoryProvider = StreamProvider<List<OrderModel>>((ref) {
  const completedStatuses = ['Completed', 'Cancelled'];

  return _ordersFromQuery(
    FirebaseFirestore.instance
        .collection('orders')
        .where('status', whereIn: completedStatuses)
        .orderBy('createdAt', descending: true)
        .limit(50),
  );
});
