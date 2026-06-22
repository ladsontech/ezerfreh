import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/data/services/order_service.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    'Assigned',
    'Picked Up',
    'On the Way',
    'Arrived',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    final content = ordersAsync.when(
      data: _buildOrders,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );

    if (widget.isTab) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: content,
    );
  }

  Widget _buildOrders(List<OrderModel> orders) {
    final filtered = _filter == 'All'
        ? orders
        : orders.where((order) => order.orderStatus.label == _filter).toList();

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
                  _OrdersSummary(orders: orders),
                  const SizedBox(height: 12),
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
                        final wide = constraints.maxWidth >= 900;
                        if (!wide) {
                          return Column(
                            children: filtered
                                .map(
                                  (order) => _AdminOrderCard(
                                    order: order,
                                    onStatusChanged: _updateStatus,
                                  ),
                                )
                                .toList(),
                          );
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: filtered
                              .map(
                                (order) => SizedBox(
                                  width: (constraints.maxWidth - 12) / 2,
                                  child: _AdminOrderCard(
                                    order: order,
                                    onStatusChanged: _updateStatus,
                                  ),
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

  Future<void> _updateStatus(OrderModel order, OrderStatus status) async {
    if (order.orderStatus == status) return;

    try {
      await ref.read(orderServiceProvider).updateStatus(order.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order.shortId} updated to ${status.label}.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $error')));
    }
  }
}

class _OrdersSummary extends StatelessWidget {
  final List<OrderModel> orders;

  const _OrdersSummary({required this.orders});

  @override
  Widget build(BuildContext context) {
    final active = orders.where((o) => o.orderStatus.isActive).length;
    final inDelivery = orders
        .where((o) => o.orderStatus.isDeliveryPhase)
        .length;
    final revenue = orders
        .where((o) => o.orderStatus != OrderStatus.cancelled)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _Pill(
          icon: Icons.receipt_long_outlined,
          label: 'Total',
          value: '${orders.length}',
        ),
        _Pill(icon: Icons.bolt_outlined, label: 'Active', value: '$active'),
        _Pill(
          icon: Icons.delivery_dining_outlined,
          label: 'Delivery',
          value: '$inDelivery',
        ),
        _Pill(
          icon: Icons.payments_outlined,
          label: 'Revenue',
          value: 'UGX ${NumberFormat.compact().format(revenue)}',
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Pill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOrderCard extends StatefulWidget {
  final OrderModel order;
  final void Function(OrderModel order, OrderStatus status) onStatusChanged;

  const _AdminOrderCard({required this.order, required this.onStatusChanged});

  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.orderStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(
        borderColor: status.color.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Icon(status.icon, color: status.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ${order.shortId}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        DateFormat.yMMMd().add_jm().format(order.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: OrderStatusBadge(status: status, compact: true),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OrderDeliveryTimeline(status: status, compact: true),
          const SizedBox(height: 12),
          Text(
            '${order.totalItems} items, UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (order.fullAddress != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.fullAddress!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (_expanded) ...[
            const Divider(height: 24),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'UGX ${NumberFormat('#,##0').format(item.price * item.quantity)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<OrderStatus>(
              initialValue: status,
              decoration: const InputDecoration(
                labelText: 'Update status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: OrderStatus.adminFlow
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) widget.onStatusChanged(order, value);
              },
            ),
          ],
        ],
      ),
    );
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

BoxDecoration _cardDecoration({Color? borderColor}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor ?? const Color(0xFFE8ECE8)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
