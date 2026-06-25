import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/core/providers/user_provider.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
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
        .where((o) => o.orderStatus == OrderStatus.pending)
        .length;
    final deliveryOrders = orders
        .where((o) => o.orderStatus.isDeliveryPhase)
        .length;
    final revenue = orders
        .where((o) => o.orderStatus != OrderStatus.cancelled)
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
    final customers = users.where((u) => u.role == 'customer').length;
    final riders = users.where((u) => u.role == 'rider').length;

    final loadingOrders = ordersAsync.isLoading && ordersAsync.asData == null;
    final loadingProducts =
        productsAsync.isLoading && productsAsync.asData == null;
    final loadingUsers = usersAsync.isLoading && usersAsync.asData == null;
    final hasErrors =
        productsAsync.hasError || ordersAsync.hasError || usersAsync.hasError;

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () async {
        ref.invalidate(allProductsProvider);
        ref.invalidate(adminOrdersProvider);
        ref.invalidate(allUsersProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OverviewPanel(
                    activeOrders: activeOrders,
                    pendingOrders: pendingOrders,
                    revenue: revenue,
                    loading: loadingOrders,
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
                  const SizedBox(height: 20),
                  const _SectionTitle('Quick Stats'),
                  const SizedBox(height: 10),
                  _ResponsiveGrid(
                    children: [
                      _StatTile(
                        data: _StatData(
                          label: 'Products',
                          value: _countValue(loadingProducts, products.length),
                          detail: 'Inventory listed',
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      _StatTile(
                        data: _StatData(
                          label: 'Active Orders',
                          value: _countValue(loadingOrders, activeOrders),
                          detail: '$deliveryOrders in delivery',
                          icon: Icons.local_shipping_outlined,
                          color: const Color(0xFF0984E3),
                        ),
                      ),
                      _StatTile(
                        data: _StatData(
                          label: 'Customers',
                          value: _countValue(loadingUsers, customers),
                          detail: '$riders rider accounts',
                          icon: Icons.people_outline,
                          color: const Color(0xFF6C5CE7),
                        ),
                      ),
                      _StatTile(
                        data: _StatData(
                          label: 'Revenue',
                          value: _moneyValue(loadingOrders, revenue),
                          detail: 'Non-cancelled orders',
                          icon: Icons.payments_outlined,
                          color: const Color(0xFFFDAA5E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Workspaces'),
                  const SizedBox(height: 10),
                  _ResponsiveGrid(
                    children: [
                      _ActionTile(
                        data: _ActionData(
                          label: 'Inventory',
                          detail: 'Search and edit products',
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xFF2E7D32),
                          onTap: () => context.go('/admin/products'),
                        ),
                      ),
                      _ActionTile(
                        data: _ActionData(
                          label: 'Add Product',
                          detail: 'Create a fresh listing',
                          icon: Icons.add_photo_alternate_outlined,
                          color: const Color(0xFFFDAA5E),
                          onTap: () => context.push('/admin/upload'),
                        ),
                      ),
                      _ActionTile(
                        data: _ActionData(
                          label: 'Orders',
                          detail: 'Update fulfillment status',
                          icon: Icons.receipt_long_outlined,
                          color: const Color(0xFF0984E3),
                          onTap: () => context.push('/admin/orders'),
                        ),
                      ),
                      _ActionTile(
                        data: _ActionData(
                          label: 'Users',
                          detail: 'Review account roles',
                          icon: Icons.people_outline,
                          color: const Color(0xFF6C5CE7),
                          onTap: () => context.push('/admin/users'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _RecentOrdersPanel(
                    orders: orders.take(5).toList(),
                    loading: loadingOrders,
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

class _OverviewPanel extends StatelessWidget {
  final int activeOrders;
  final int pendingOrders;
  final double revenue;
  final bool loading;
  final VoidCallback onAddProduct;
  final VoidCallback onViewOrders;

  const _OverviewPanel({
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
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Color(0xFF2E7D32),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Store Overview',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$activeOrders active, $pendingOrders pending, $revenueText revenue',
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.35,
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
                label: const Text('Add Product'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
              children: [summary, const SizedBox(height: 14), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: summary),
              const SizedBox(width: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFDFAC)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFFC77700),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Some live data could not sync: $failed.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7A4B00),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final _StatData data;

  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
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
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 19, color: data.color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade900,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _ActionData data;

  const _ActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 86),
          padding: const EdgeInsets.all(14),
          decoration: _panelDecoration(),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  final List<OrderModel> orders;
  final bool loading;
  final VoidCallback onViewAll;

  const _RecentOrdersPanel({
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
            const Expanded(child: _SectionTitle('Recent Orders')),
            TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: _panelDecoration(),
          clipBehavior: Clip.antiAlias,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : orders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                  child: Center(
                    child: Text(
                      'No orders placed yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < orders.length; i++) ...[
                      _RecentOrderRow(order: orders[i]),
                      if (i != orders.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade100,
                        ),
                    ],
                  ],
                ),
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

    return Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final titleBlock = Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.1),
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
                      order.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.shortId} · ${order.totalItems} items · ${DateFormat.MMMd().add_jm().format(order.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (order.hasContactInfo) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            order.customerPhone!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final amountBlock = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                'UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              OrderStatusBadge(status: status, compact: true),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleBlock, const SizedBox(height: 10), amountBlock],
            );
          }

          return Row(
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 16),
              Flexible(child: amountBlock),
            ],
          );
        },
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  const _StatData({
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

BoxDecoration _panelDecoration({Color? borderColor}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor ?? const Color(0xFFE8ECE8)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.025),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
