import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/core/providers/user_provider.dart';
import 'package:ezer_fresh/src/core/services/data_setup_service.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final activeOrders = orders.where((order) => order.orderStatus.isActive).length;
    final completedOrders = orders
        .where((order) => order.orderStatus == OrderStatus.completed)
        .length;
    final revenue = orders
        .where((order) => order.orderStatus != OrderStatus.cancelled)
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allProductsProvider);
        ref.invalidate(adminOrdersProvider);
        ref.invalidate(allUsersProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _LiveHeader(
            title: 'Admin Control',
            subtitle: 'Live shop totals, orders, inventory, and users.',
            actionLabel: 'Add Product',
            onAction: () => context.push('/admin/upload'),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.6 : 2.0,
                children: [
                  _MetricCard(
                    label: 'Revenue',
                    value: 'UGX ${NumberFormat.compact().format(revenue)}',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF2E7D32),
                  ),
                  _MetricCard(
                    label: 'Products',
                    value: '${products.length}',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF0984E3),
                  ),
                  _MetricCard(
                    label: 'Active Orders',
                    value: '$activeOrders',
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFFFDAA5E),
                  ),
                  _MetricCard(
                    label: 'Users',
                    value: '${users.length}',
                    icon: Icons.people_outline,
                    color: const Color(0xFF6C5CE7),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _SectionPanel(
            title: 'Quick Actions',
            trailing: const LiveIndicator(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ActionButton(
                      wide: wide,
                      label: 'Sync Inventory',
                      subtitle: 'Upload or refresh products',
                      icon: Icons.sync,
                      color: const Color(0xFF2E7D32),
                      onTap: () => _runSync(context, ref, _SyncMode.all),
                    ),
                    _ActionButton(
                      wide: wide,
                      label: 'Repair Categories',
                      subtitle: 'Fix herbs and spices',
                      icon: Icons.eco_outlined,
                      color: const Color(0xFF00B894),
                      onTap: () => _runSync(context, ref, _SyncMode.special),
                    ),
                    _ActionButton(
                      wide: wide,
                      label: 'Clean Duplicates',
                      subtitle: 'Remove repeated records',
                      icon: Icons.cleaning_services_outlined,
                      color: const Color(0xFFFF6B6B),
                      onTap: () => _runSync(context, ref, _SyncMode.cleanup),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _SectionPanel(
            title: 'Recent Orders',
            trailing: TextButton(
              onPressed: () => context.go('/admin/orders'),
              child: const Text('View all'),
            ),
            child: orders.isEmpty
                ? const _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    message: 'New customer orders will appear here instantly.',
                  )
                : Column(
                    children: orders
                        .take(5)
                        .map((order) => _RecentOrderTile(order: order))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionPanel(
            title: 'Completion',
            child: LinearProgressIndicator(
              minHeight: 10,
              borderRadius: BorderRadius.circular(99),
              value: orders.isEmpty ? 0 : completedOrders / orders.length,
              backgroundColor: const Color(0xFFE8ECE8),
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runSync(
    BuildContext context,
    WidgetRef ref,
    _SyncMode mode,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      switch (mode) {
        case _SyncMode.all:
          await DataSetupService.initializeInventory();
          break;
        case _SyncMode.special:
          await DataSetupService.forceRepairSpecialized();
          break;
        case _SyncMode.cleanup:
          await DataSetupService.cleanupAllDuplicates();
          await DataSetupService.initializeInventory();
          break;
      }

      ref.invalidate(allProductsProvider);
      ref.invalidate(adminOrdersProvider);
      for (final id in ['1', '2', '3', '4']) {
        ref.invalidate(productsProvider(id));
      }

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory updated successfully.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inventory update failed: $error')),
      );
    }
  }
}

enum _SyncMode { all, special, cleanup }

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      data: (users) {
        final admins = users.where((user) => user.role == 'admin').length;
        final riders = users.where((user) => user.role == 'rider').length;
        final customers = users.where((user) => user.role == 'customer').length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _LiveHeader(
              title: 'Users',
              subtitle: 'Accounts update in real time as people join.',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 4 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: columns == 4 ? 2.5 : 2.0,
                  children: [
                    _MetricCard(
                      label: 'Total',
                      value: '${users.length}',
                      icon: Icons.people_outline,
                      color: const Color(0xFF0984E3),
                    ),
                    _MetricCard(
                      label: 'Admins',
                      value: '$admins',
                      icon: Icons.admin_panel_settings_outlined,
                      color: const Color(0xFF2E7D32),
                    ),
                    _MetricCard(
                      label: 'Riders',
                      value: '$riders',
                      icon: Icons.delivery_dining_outlined,
                      color: const Color(0xFF00B894),
                    ),
                    _MetricCard(
                      label: 'Customers',
                      value: '$customers',
                      icon: Icons.person_outline,
                      color: const Color(0xFFFDAA5E),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (users.isEmpty)
              const _EmptyState(
                icon: Icons.people_outline,
                title: 'No users found',
                message: 'User accounts will appear here.',
              )
            else
              ...users.map((user) => _UserTile(user: user)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class AdminSettingsTab extends StatelessWidget {
  const AdminSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: const [
        _LiveHeader(
          title: 'Settings',
          subtitle: 'Profile and shop preferences live here.',
        ),
        SizedBox(height: 16),
        _EmptyState(
          icon: Icons.settings_outlined,
          title: 'Settings coming soon',
          message: 'Core admin actions are available from the dashboard.',
        ),
      ],
    );
  }
}

class _LiveHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _LiveHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.lato(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel!),
            ),
          ] else
            const LiveIndicator(),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionPanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool wide;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.wide,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 220 : double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final OrderModel order;

  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(order.orderStatus.icon, color: order.orderStatus.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ${order.shortId}',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${order.totalItems} items, ${DateFormat.yMMMd().add_jm().format(order.createdAt)}',
                  style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          OrderStatusBadge(status: order.orderStatus, compact: true),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final color = switch (user.role) {
      'admin' => const Color(0xFF2E7D32),
      'rider' => const Color(0xFF00B894),
      _ => const Color(0xFFFDAA5E),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.person_outline, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: GoogleFonts.lato(fontWeight: FontWeight.w800)),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(user.role.toUpperCase()),
            side: BorderSide.none,
            backgroundColor: color.withValues(alpha: 0.12),
            labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.grey[500]),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE8ECE8)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
