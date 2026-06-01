import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login, size: 56, color: Colors.green[200]),
            const SizedBox(height: 12),
            const Text('Log in to view your orders.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    final ordersAsync = ref.watch(customerOrdersProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _EmptyCustomerOrders(onShop: () => context.go('/home'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final active = orders
                      .where(
                        (order) => ![
                          'completed',
                          'cancelled',
                        ].contains(order.status.toLowerCase()),
                      )
                      .length;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: constraints.maxWidth >= 720 ? 3 : 1,
                    childAspectRatio: constraints.maxWidth >= 720 ? 3.4 : 4.6,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _SummaryCard(
                        label: 'Total Orders',
                        value: '${orders.length}',
                        icon: Icons.receipt_long_outlined,
                        color: Colors.blue,
                      ),
                      _SummaryCard(
                        label: 'Active',
                        value: '$active',
                        icon: Icons.local_shipping_outlined,
                        color: Colors.orange,
                      ),
                      _SummaryCard(
                        label: 'Spent',
                        value:
                            'UGX ${NumberFormat.compact().format(_totalSpent(orders))}',
                        icon: Icons.payments_outlined,
                        color: Colors.green,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CustomerOrderCard(order: order),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  double _totalSpent(List<OrderModel> orders) {
    return orders
        .where((order) => order.status.toLowerCase() != 'cancelled')
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  final OrderModel order;

  const _CustomerOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  _getStatusImagePath(order.status),
                  errorBuilder: (context, _, __) =>
                      Icon(Icons.receipt, color: statusColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, order.id.length < 8 ? order.id.length : 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      DateFormat.yMMMd().add_jm().format(order.createdAt),
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...order.items
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Expanded(child: Text('${item.quantity}x ${item.name}')),
                      Text(
                        'UGX ${NumberFormat('#,##0').format(item.price * item.quantity)}',
                      ),
                    ],
                  ),
                ),
              ),
          if (order.items.length > 3)
            Text(
              '+${order.items.length - 3} more items',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          const Divider(height: 24),
          Row(
            children: [
              const Text('Total', style: TextStyle(color: Colors.black54)),
              const Spacer(),
              Text(
                'UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCustomerOrders extends StatelessWidget {
  final VoidCallback onShop;

  const _EmptyCustomerOrders({required this.onShop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECE8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.green[200],
            ),
            const SizedBox(height: 14),
            const Text(
              'No orders yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your fresh produce orders and delivery progress will appear here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onShop,
              icon: const Icon(Icons.shopping_basket_outlined),
              label: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }
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

String _getStatusImagePath(String status) {
  switch (status.toLowerCase()) {
    case 'out for delivery':
      return 'assets/status/on_the_way.png';
    case 'completed':
      return 'assets/status/completed.png';
    case 'cancelled':
      return 'assets/status/cancelled.png';
    case 'processing':
    case 'pending':
    default:
      return 'assets/status/completed.png'; // Fallback
  }
}
