import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Stream<List<OrderModel>> _ordersFromQuery(Query query) {
  return query.snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
      );
}

Future<List<OrderModel>> _fetchOrdersFromQuery(Query query) async {
  try {
    // Try cached first, fallback to server
    final snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
  } catch (_) {
    final cached = await query.get(const GetOptions(source: Source.cache));
    return cached.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
  }
}

final adminOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return _ordersFromQuery(
    FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(30),
  );
});

/// All orders for riders — real-time feed of active orders in the system.
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
        .limit(25),
  );
});

/// Active orders require real-time streaming
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
        .orderBy('createdAt', descending: true)
        .limit(30),
  );
});

/// Completed rider history loaded with query limit to prevent massive read costs
final riderHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  const completedStatuses = ['Completed', 'Cancelled'];

  return _fetchOrdersFromQuery(
    FirebaseFirestore.instance
        .collection('orders')
        .where('status', whereIn: completedStatuses)
        .orderBy('createdAt', descending: true)
        .limit(25),
  );
});
