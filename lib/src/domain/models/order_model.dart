import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime createdAt;
  final String status;
  final String? address;
  final String? apartmentSuite;
  final double? latitude;
  final double? longitude;
  final String? riderId;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    required this.status,
    this.address,
    this.apartmentSuite,
    this.latitude,
    this.longitude,
    this.riderId,
    this.updatedAt,
  });

  OrderStatus get orderStatus => OrderStatus.fromString(status);

  int get totalItems =>
      items.fold<int>(0, (total, item) => total + item.quantity);

  String get shortId {
    if (id.length <= 8) return '#${id.toUpperCase()}';
    return '#${id.substring(0, 8).toUpperCase()}';
  }

  String? get fullAddress {
    if (address == null) return null;
    if (apartmentSuite != null && apartmentSuite!.isNotEmpty) {
      return '$address ($apartmentSuite)';
    }
    return address;
  }

  bool get hasLocation => latitude != null && longitude != null;

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'Pending',
      address: data['address'],
      apartmentSuite: data['apartmentSuite'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      riderId: data['riderId'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
