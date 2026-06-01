import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
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
  String _statusFilter = 'All';

  static const _statuses = [
    'Pending',
    'Processing',
    'Ready for Pickup',
    'Out for Delivery',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsyncValue = ref.watch(adminOrdersProvider);

    Widget content = ordersAsyncValue.when(
      data: (orders) {
        final filtered = _statusFilter == 'All'
            ? orders
            : orders
                  .where(
                    (order) =>
                        order.status.toLowerCase() ==
                        _statusFilter.toLowerCase(),
                  )
                  .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(context, orders),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyOrdersState(status: _statusFilter)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 900;
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => wide
                              ? _buildOrderRow(context, filtered[index])
                              : _buildOrderCard(context, filtered[index]),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );

    if (widget.isTab) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: content,
    );
  }

  Widget _buildToolbar(BuildContext context, List<OrderModel> orders) {
    final active = orders
        .where(
          (order) =>
              !['completed', 'cancelled'].contains(order.status.toLowerCase()),
        )
        .length;
    final revenue = orders
        .where((order) => order.status.toLowerCase() != 'cancelled')
        .fold<double>(0, (total, order) => total + order.totalAmount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _MetricPill(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            value: '${orders.length}',
            color: Colors.blue,
          ),
          _MetricPill(
            icon: Icons.local_shipping_outlined,
            label: 'Active',
            value: '$active',
            color: Colors.orange,
          ),
          _MetricPill(
            icon: Icons.payments_outlined,
            label: 'Revenue',
            value: 'UGX ${NumberFormat.compact().format(revenue)}',
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'All', label: Text('All')),
              ButtonSegment(value: 'Pending', label: Text('Pending')),
              ButtonSegment(value: 'Processing', label: Text('Processing')),
              ButtonSegment(value: 'Out for Delivery', label: Text('Delivery')),
              ButtonSegment(value: 'Completed', label: Text('Done')),
            ],
            selected: {_statusFilter},
            onSelectionChanged: (selected) =>
                setState(() => _statusFilter = selected.first),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          _StatusIcon(status: order.status),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _OrderIdentity(order: order)),
          Expanded(flex: 3, child: _OrderItemsPreview(order: order)),
          Expanded(
            child: Text(
              'UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 210,
            child: _StatusMenu(
              value: order.status,
              statuses: _statuses,
              onChanged: (status) => _updateStatus(context, order, status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusIcon(status: order.status),
              const SizedBox(width: 12),
              Expanded(child: _OrderIdentity(order: order)),
            ],
          ),
          const SizedBox(height: 16),
          _OrderItemsPreview(order: order),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: _StatusMenu(
                  value: order.status,
                  statuses: _statuses,
                  onChanged: (status) => _updateStatus(context, order, status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    OrderModel order,
    String status,
  ) async {
    if (status == order.status) return;

    await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${_shortId(order.id)} moved to $status')),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE8ECE8)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(8),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _OrderIdentity extends StatelessWidget {
  final OrderModel order;

  const _OrderIdentity({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order ${_shortId(order.id)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat.yMMMd().add_jm().format(order.createdAt),
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _OrderItemsPreview extends StatelessWidget {
  final OrderModel order;

  const _OrderItemsPreview({required this.order});

  @override
  Widget build(BuildContext context) {
    final visibleItems = order.items.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visibleItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${item.quantity}x ${item.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (order.items.length > visibleItems.length)
          Text(
            '+${order.items.length - visibleItems.length} more items',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
      ],
    );
  }
}

class _StatusMenu extends StatelessWidget {
  final String value;
  final List<String> statuses;
  final ValueChanged<String> onChanged;

  const _StatusMenu({
    required this.value,
    required this.statuses,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedValue = statuses.firstWhere(
      (status) => status.toLowerCase() == value.toLowerCase(),
      orElse: () => statuses.first,
    );

    return DropdownButtonFormField<String>(
      initialValue: normalizedValue,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: statuses
          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
          .toList(),
      onChanged: (status) {
        if (status != null) onChanged(status);
      },
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_statusIcon(status), color: color),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  final String status;

  const _EmptyOrdersState({required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(status == 'All' ? 'No orders yet' : 'No $status orders'),
        ],
      ),
    );
  }
}

String _shortId(String id) {
  if (id.length <= 8) return '#${id.toUpperCase()}';
  return '#${id.substring(0, 8).toUpperCase()}';
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.orange;
    case 'processing':
      return Colors.blue;
    case 'ready for pickup':
      return Colors.deepPurple;
    case 'out for delivery':
      return Colors.teal;
    case 'completed':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

IconData _statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Icons.hourglass_empty;
    case 'processing':
      return Icons.inventory_2_outlined;
    case 'ready for pickup':
      return Icons.storefront_outlined;
    case 'out for delivery':
      return Icons.local_shipping_outlined;
    case 'completed':
      return Icons.check_circle_outline;
    case 'cancelled':
      return Icons.cancel_outlined;
    default:
      return Icons.receipt_long_outlined;
  }
}
