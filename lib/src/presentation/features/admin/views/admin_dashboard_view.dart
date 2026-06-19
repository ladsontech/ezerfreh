import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/core/providers/user_provider.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);
    final ordersAsync = ref.watch(adminOrdersProvider);
    final usersAsync = ref.watch(allUsersProvider);

    final products = productsAsync.asData?.value ?? [];
    final orders = ordersAsync.asData?.value ?? [];
    final users = usersAsync.asData?.value ?? [];

    final activeOrders = orders.where((o) => o.orderStatus.isActive).length;
    final pendingOrders = orders
        .where((o) => o.orderStatus.label == 'Pending')
        .length;
    final deliveryOrders = orders
        .where((o) => o.orderStatus.isDeliveryPhase)
        .length;
    final revenue = orders
        .where(
          (o) =>
              !o.orderStatus.isTerminal || o.orderStatus.label != 'Cancelled',
        )
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
    final customers = users.where((u) => u.role == 'customer').length;

    final hasErrors =
        productsAsync.hasError || ordersAsync.hasError || usersAsync.hasError;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allProductsProvider);
        ref.invalidate(adminOrdersProvider);
        ref.invalidate(allUsersProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OverviewHero(
                    activeOrders: activeOrders,
                    pendingOrders: pendingOrders,
                    revenue: revenue,
                    loading:
                        ordersAsync.isLoading && ordersAsync.asData == null,
                    onAddProduct: () => context.push('/admin/upload'),
                    onViewOrders: () => context.push('/admin/orders'),
                  ),
                  if (hasErrors) ...[
                    const SizedBox(height: 12),
                    _SyncWarning(
                      productsFailed: productsAsync.hasError,
                      ordersFailed: ordersAsync.hasError,
                      usersFailed: usersAsync.hasError,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _MetricGrid(
                    metrics: [
                      _MetricData(
                        label: 'Products',
                        value: _countValue(
                          productsAsync.isLoading &&
                              productsAsync.asData == null,
                          products.length,
                        ),
                        detail: 'Inventory listed',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF2E7D32),
                      ),
                      _MetricData(
                        label: 'Active Orders',
                        value: _countValue(
                          ordersAsync.isLoading && ordersAsync.asData == null,
                          activeOrders,
                        ),
                        detail: '$deliveryOrders in delivery',
                        icon: Icons.bolt_outlined,
                        color: const Color(0xFF0984E3),
                      ),
                      _MetricData(
                        label: 'Customers',
                        value: _countValue(
                          usersAsync.isLoading && usersAsync.asData == null,
                          customers,
                        ),
                        detail: '${users.length} total users',
                        icon: Icons.people_outline,
                        color: const Color(0xFF6C5CE7),
                      ),
                      _MetricData(
                        label: 'Revenue',
                        value: _moneyValue(
                          ordersAsync.isLoading && ordersAsync.asData == null,
                          revenue,
                        ),
                        detail: 'Non-cancelled orders',
                        icon: Icons.payments_outlined,
                        color: const Color(0xFFFDAA5E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Workspaces',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1F2A24),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ActionGrid(
                    actions: [
                      _ActionData(
                        label: 'Products',
                        detail: 'Search, edit, and remove stock',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF2E7D32),
                        onTap: () => context.go('/admin/products'),
                      ),
                      _ActionData(
                        label: 'New Product',
                        detail: 'Add a fresh listing',
                        icon: Icons.add_photo_alternate_outlined,
                        color: const Color(0xFFFDAA5E),
                        onTap: () => context.push('/admin/upload'),
                      ),
                      _ActionData(
                        label: 'Orders',
                        detail: 'Update fulfillment status',
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFF0984E3),
                        onTap: () => context.push('/admin/orders'),
                      ),
                      _ActionData(
                        label: 'Users',
                        detail: 'Review customer roles',
                        icon: Icons.people_outline,
                        color: const Color(0xFF6C5CE7),
                        onTap: () => context.push('/admin/users'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _RecentOrders(
                    orders: orders.take(5).toList(),
                    loading:
                        ordersAsync.isLoading && ordersAsync.asData == null,
                    onViewAll: () => context.push('/admin/orders'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _countValue(bool loading, int value) => loading ? '...' : '$value';

  String _moneyValue(bool loading, double value) {
    if (loading) return '...';
    return 'UGX ${NumberFormat.compact().format(value)}';
  }
}

class _OverviewHero extends StatelessWidget {
  final int activeOrders;
  final int pendingOrders;
  final double revenue;
  final bool loading;
  final VoidCallback onAddProduct;
  final VoidCallback onViewOrders;

  const _OverviewHero({
    required this.activeOrders,
    required this.pendingOrders,
    required this.revenue,
    required this.loading,
    required this.onAddProduct,
    required this.onViewOrders,
  });

  @override
  Widget build(BuildContext context) {
    final revenueText = loading
        ? '...'
        : 'UGX ${NumberFormat.compact().format(revenue)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF143D2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF265D43)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Admin Command Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Keep the store moving',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$activeOrders active orders, $pendingOrders waiting, $revenueText booked.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Product'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFDAA5E),
                  foregroundColor: const Color(0xFF1E170F),
                  minimumSize: const Size(148, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onViewOrders,
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Orders'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                  minimumSize: const Size(120, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 18), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _SyncWarning extends StatelessWidget {
  final bool productsFailed;
  final bool ordersFailed;
  final bool usersFailed;

  const _SyncWarning({
    required this.productsFailed,
    required this.ordersFailed,
    required this.usersFailed,
  });

  @override
  Widget build(BuildContext context) {
    final failed = [
      if (productsFailed) 'products',
      if (ordersFailed) 'orders',
      if (usersFailed) 'users',
    ].join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD9A3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFFC77700)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Some live data could not sync: $failed.',
              style: const TextStyle(
                color: Color(0xFF7A4B00),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricData> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 940
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _MetricTile(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _MetricData metric;

  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E8E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(metric.icon, size: 18, color: metric.color),
              ),
              const Spacer(),
              Icon(Icons.trending_up, size: 16, color: Colors.grey[400]),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2A24),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5E665F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final List<_ActionData> actions;

  const _ActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 940
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions
              .map(
                (action) => SizedBox(
                  width: width,
                  child: _ActionTile(action: action),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _ActionData action;

  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE1E8E0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, color: action.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2A24),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF9AA39D)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  final List<OrderModel> orders;
  final bool loading;
  final VoidCallback onViewAll;

  const _RecentOrders({
    required this.orders,
    required this.loading,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Orders',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1F2A24),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (loading)
          const LinearProgressIndicator(minHeight: 2)
        else if (orders.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1E8E0)),
            ),
            child: const Text(
              'No orders yet.',
              style: TextStyle(color: Color(0xFF6A716C)),
            ),
          )
        else
          Column(
            children: orders
                .map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RecentOrderRow(order: order),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  final OrderModel order;

  const _RecentOrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(status.icon, color: status.color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.shortId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.totalItems} items - ${DateFormat.MMMd().add_jm().format(order.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              OrderStatusBadge(status: status, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

class _ActionData {
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionData({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
