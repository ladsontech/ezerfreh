import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

class OrderService {
  final FirebaseFirestore _firestore;

  OrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> updateStatus(
    String orderId,
    OrderStatus status, {
    String? riderId,
  }) async {
    final data = <String, dynamic>{
      'status': status.label,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (riderId != null) {
      data['riderId'] = riderId;
      if (status == OrderStatus.assigned) {
        data['assignedAt'] = FieldValue.serverTimestamp();
      }
    }

    await _firestore.collection('orders').doc(orderId).update(data);
  }

  Future<void> advanceRiderStatus({
    required String orderId,
    required OrderStatus current,
    required String riderId,
  }) async {
    final next = current.nextRiderStatus;
    if (next == null) return;

    final data = <String, dynamic>{
      'status': next.label,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (next == OrderStatus.assigned) {
      data['riderId'] = riderId;
      data['assignedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('orders').doc(orderId).update(data);
  }
}
