import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/user_provider.dart';
import 'package:ezer_fresh/src/data/services/order_service.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_detail_card.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simplified, clean admin Orders screen. Every order card is the shared
/// [OrderDetailCard] — the exact same widget the rider dashboard uses — so
/// admins see everything a rider sees (contact info, full address, items,
/// delivery timeline). The footer adds admin-only controls: full status
/// override and rider assignment.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  final bool isTab;
  const AdminOrdersScreen({super.key, this.isTab = false});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _filter = 'All';

  static const _filters = [
    'All',
    'Pending',
    'Processing',
    'Ready for Pickup',
    'Out for Delivery',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final ridersAsync = ref.watch(allUsersProvider);
    final riders = (ridersAsync.asData?.value ?? [])
        .where((user) => user.role == 'rider')
        .toList();

    final content = ordersAsync.when(
      data: (orders) => _buildOrders(orders, riders),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );

    if (widget.isTab) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: content,
    );
  }

  Widget _buildOrders(List<OrderModel> orders, List<AppUser> riders) {
    final filtered = _filterOrders(orders);
    final riderNames = {for (final rider in riders) rider.id: rider.name};

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminOrdersProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'All Orders',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${orders.length} total',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OrderStatusChipBar(
                    selected: _filter,
                    options: _filters,
                    onSelected: (value) => setState(() => _filter = value),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    _EmptyOrders(filter: _filter)
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = filtered
                            .map(
                              (order) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: OrderDetailCard(
                                  order: order,
                                  itemsExpandedByDefault: false,
                                  assignedRiderLabel: order.riderId != null
                                      ? (riderNames[order.riderId] ??
                                            'Unknown rider')
                                      : null,
                                  footer: _AdminCardFooter(
                                    order: order,
                                    riders: riders,
                                  ),
                                ),
                              ),
                            )
                            .toList();

                        final wide = constraints.maxWidth >= 900;
                        if (!wide) return Column(children: cards);

                        return Wrap(
                          spacing: 12,
                          children: cards
                              .map(
                                (card) => SizedBox(
                                  width: (constraints.maxWidth - 12) / 2,
                                  child: card,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    return switch (_filter) {
      'All' => orders,
      'Pending' =>
        orders.where((o) => o.orderStatus == OrderStatus.pending).toList(),
      'Processing' =>
        orders.where((o) => o.orderStatus == OrderStatus.processing).toList(),
      'Ready for Pickup' =>
        orders
            .where((o) => o.orderStatus == OrderStatus.readyForPickup)
            .toList(),
      'Out for Delivery' =>
        orders.where((o) => o.orderStatus.isDeliveryPhase).toList(),
      'Completed' =>
        orders.where((o) => o.orderStatus == OrderStatus.completed).toList(),
      'Cancelled' =>
        orders.where((o) => o.orderStatus == OrderStatus.cancelled).toList(),
      _ => orders,
    };
  }
}

/// Admin-only footer: full status override plus rider assignment. Assigning
/// a rider doesn't touch status — it just writes `riderId`, reusing
/// `OrderService.updateStatus`'s existing support for that (see
/// `order_service.dart`), so no new backend call was needed.
class _AdminCardFooter extends ConsumerStatefulWidget {
  final OrderModel order;
  final List<AppUser> riders;

  const _AdminCardFooter({required this.order, required this.riders});

  @override
  ConsumerState<_AdminCardFooter> createState() => _AdminCardFooterState();
}

class _AdminCardFooterState extends ConsumerState<_AdminCardFooter> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    // Guard against DropdownButtonFormField's assertion error if the
    // assigned rider no longer exists in the current riders list (deleted
    // account, role changed away from "rider", etc.).
    final currentRiderId = widget.riders.any((r) => r.id == order.riderId)
        ? order.riderId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<OrderStatus>(
          key: ValueKey('status-${order.id}-${order.status}'),
          initialValue: order.orderStatus,
          decoration: InputDecoration(
            labelText: 'Status',
            isDense: true,
            prefixIcon: const Icon(Icons.sync_alt_outlined, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          items: OrderStatus.adminFlow
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 16, color: item.color),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(item.label, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: _updating
              ? null
              : (value) {
                  if (value != null) _updateStatus(value);
                },
        ),
        if (widget.riders.isNotEmpty) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('rider-${order.id}-$currentRiderId'),
            initialValue: currentRiderId,
            decoration: InputDecoration(
              labelText: 'Assign rider',
              isDense: true,
              prefixIcon: const Icon(
                Icons.delivery_dining_outlined,
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            hint: const Text('Unassigned'),
            items: widget.riders
                .map(
                  (rider) => DropdownMenuItem(
                    value: rider.id,
                    child: Text(
                      rider.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _updating
                ? null
                : (value) {
                    if (value != null) _assignRider(value);
                  },
          ),
        ],
      ],
    );
  }

  Future<void> _updateStatus(OrderStatus status) async {
    if (status == widget.order.orderStatus) return;
    setState(() => _updating = true);
    try {
      await ref.read(orderServiceProvider).updateStatus(widget.order.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to ${status.label}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $error')));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _assignRider(String riderId) async {
    setState(() => _updating = true);
    try {
      await ref
          .read(orderServiceProvider)
          .updateStatus(
            widget.order.id,
            widget.order.orderStatus,
            riderId: riderId,
          );
      if (!mounted) return;
      final rider = widget.riders.firstWhere((r) => r.id == riderId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Assigned to ${rider.name}.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Assignment failed: $error')));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

class _EmptyOrders extends StatelessWidget {
  final String filter;

  const _EmptyOrders({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          filter == 'All' ? 'No orders yet' : 'No $filter orders',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
