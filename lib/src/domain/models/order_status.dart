import 'package:flutter/material.dart';

enum OrderStatus {
  pending,
  processing,
  readyForPickup,
  assigned,
  pickedUp,
  onTheWay,
  arrived,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.arrived:
        return 'Arrived';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'pending' => OrderStatus.pending,
      'processing' => OrderStatus.processing,
      'ready for pickup' => OrderStatus.readyForPickup,
      'assigned' => OrderStatus.assigned,
      'picked up' => OrderStatus.pickedUp,
      'on the way' => OrderStatus.onTheWay,
      'out for delivery' => OrderStatus.onTheWay,
      'arrived' => OrderStatus.arrived,
      'completed' => OrderStatus.completed,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }

  bool get isTerminal =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;

  bool get isActive => !isTerminal;

  bool get isDeliveryPhase =>
      index >= OrderStatus.assigned.index &&
      index <= OrderStatus.arrived.index;

  /// Delivery milestones shown on the rider timeline.
  static const deliveryFlow = [
    OrderStatus.assigned,
    OrderStatus.pickedUp,
    OrderStatus.onTheWay,
    OrderStatus.arrived,
    OrderStatus.completed,
  ];

  /// Full lifecycle for admin management.
  static const adminFlow = [
    OrderStatus.pending,
    OrderStatus.processing,
    OrderStatus.readyForPickup,
    OrderStatus.assigned,
    OrderStatus.pickedUp,
    OrderStatus.onTheWay,
    OrderStatus.arrived,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  OrderStatus? get nextRiderStatus {
    return switch (this) {
      OrderStatus.readyForPickup => OrderStatus.assigned,
      OrderStatus.assigned => OrderStatus.pickedUp,
      OrderStatus.pickedUp => OrderStatus.onTheWay,
      OrderStatus.onTheWay => OrderStatus.arrived,
      OrderStatus.arrived => OrderStatus.completed,
      _ => null,
    };
  }

  String? get nextRiderActionLabel {
    return switch (nextRiderStatus) {
      OrderStatus.assigned => 'Accept & Assign',
      OrderStatus.pickedUp => 'Mark Picked Up',
      OrderStatus.onTheWay => 'Start Delivery',
      OrderStatus.arrived => 'Mark Arrived',
      OrderStatus.completed => 'Complete Delivery',
      _ => null,
    };
  }

  int get deliveryStepIndex {
    final index = deliveryFlow.indexOf(this);
    return index < 0 ? 0 : index;
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFFDAA5E);
      case OrderStatus.processing:
        return const Color(0xFF0984E3);
      case OrderStatus.readyForPickup:
        return const Color(0xFF6C5CE7);
      case OrderStatus.assigned:
        return const Color(0xFF00CEC9);
      case OrderStatus.pickedUp:
        return const Color(0xFF00B894);
      case OrderStatus.onTheWay:
        return const Color(0xFF00B894);
      case OrderStatus.arrived:
        return const Color(0xFF2E7D32);
      case OrderStatus.completed:
        return const Color(0xFF2E7D32);
      case OrderStatus.cancelled:
        return const Color(0xFFFF6B6B);
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_empty_rounded;
      case OrderStatus.processing:
        return Icons.inventory_2_outlined;
      case OrderStatus.readyForPickup:
        return Icons.storefront_outlined;
      case OrderStatus.assigned:
        return Icons.assignment_ind_outlined;
      case OrderStatus.pickedUp:
        return Icons.shopping_bag_outlined;
      case OrderStatus.onTheWay:
        return Icons.local_shipping_outlined;
      case OrderStatus.arrived:
        return Icons.location_on_outlined;
      case OrderStatus.completed:
        return Icons.check_circle_outline;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}
