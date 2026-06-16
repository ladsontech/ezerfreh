import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/data/services/order_service.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  final bool isTab;
  const AdminOrdersScreen({super.key, this.isTab = false});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _statusFilter = 'All';

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
    final ordersAsyncValue = ref.watch(adminOrdersProvider);

    Widget content = ordersAsyncValue.when(
      data: (orders) {
        final filtered = _statusFilter == 'All'
            ? orders
            : orders
                .where(
                  (order) =>
                      order.orderStatus.label.toLowerCase() ==
                      _statusFilter.toLowerCase(),
                )
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AdminToolbar(orders: orders),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: OrderStatusChipBar(
                selected: _statusFilter,
                options: _filters,
                onSelected: (value) => setState(() => _statusFilter = value),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyOrdersState(status: _statusFilter)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => _AdminOrderCard(
                            order: filtered[index],
                            onStatusChanged: (status) =>
                                _updateStatus(context, filtered[index], status),
                          ),
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

  Future<void> _updateStatus(
    BuildContext context,
    OrderModel order,
    OrderStatus status,
  ) async {
    if (status == order.orderStatus) return;

    try {
      await ref.read(orderServiceProvider).updateStatus(order.id, status);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order.shortId} → ${status.label}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }
}

class _AdminToolbar extends StatelessWidget {
  final List<OrderModel> orders;

  const _AdminToolbar({required this.orders});

  @override
  Widget build(BuildContext context) {
    final active = orders.where((o) => o.orderStatus.isActive).length;
    final revenue = orders
        .where((o) => o.orderStatus != OrderStatus.cancelled)
        .fold<double>(0, (total, o) => total + o.totalAmount);
    final inDelivery = orders
        .where(
          (o) =>
              o.orderStatus.index >= OrderStatus.assigned.index &&
              o.orderStatus.index <= OrderStatus.arrived.index,
        )
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order Management',
                style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const LiveIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPill(
                icon: Icons.receipt_long_outlined,
                label: 'Total',
                value: '${orders.length}',
                color: const Color(0xFF0984E3),
              ),
              _MetricPill(
                icon: Icons.local_shipping_outlined,
                label: 'Active',
                value: '$active',
                color: const Color(0xFFFDAA5E),
              ),
              _MetricPill(
                icon: Icons.delivery_dining,
                label: 'In Delivery',
                value: '$inDelivery',
                color: const Color(0xFF00B894),
              ),
              _MetricPill(
                icon: Icons.payments_outlined,
                label: 'Revenue',
                value: 'UGX ${NumberFormat.compact().format(revenue)}',
                color: const Color(0xFF2E7D32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminOrderCard extends StatefulWidget {
  final OrderModel order;
  final ValueChanged<OrderStatus> onStatusChanged;

  const _AdminOrderCard({
    required this.order,
    required this.onStatusChanged,
  });

  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.orderStatus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: OrderPanelDecoration.card(
        borderColor: status.isActive
            ? status.color.withValues(alpha: 0.2)
            : const Color(0xFFE8ECE8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(status.icon, color: status.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ${order.shortId}',
                        style: GoogleFonts.lato(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        DateFormat.yMMMd().add_jm().format(order.createdAt),
                        style: GoogleFonts.lato(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                OrderStatusBadge(status: status),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[500],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OrderDeliveryTimeline(status: status, compact: true),
          if (_expanded) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${item.quantity}x ${item.name}'),
                    ),
                    Text(
                      'UGX ${NumberFormat('#,##0').format(item.price * item.quantity)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            if (order.fullAddress != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(child: Text(order.fullAddress!)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Total: UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                if (order.updatedAt != null)
                  Text(
                    'Updated ${DateFormat.jm().format(order.updatedAt!)}',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Update Status',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OrderStatus.adminFlow.map((s) {
                final isSelected = s == status;
                return ChoiceChip(
                  label: Text(s.label),
                  selected: isSelected,
                  avatar: Icon(s.icon, size: 16, color: s.color),
                  selectedColor: s.color.withValues(alpha: 0.15),
                  onSelected: isSelected
                      ? null
                      : (_) => widget.onStatusChanged(s),
                );
              }).toList(),
            ),
          ],
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: OrderPanelDecoration.card(borderColor: Colors.grey.shade100),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.lato(fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
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
