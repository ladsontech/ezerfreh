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
import 'package:intl/intl.dart';

// ─── Overview Tab ────────────────────────────────────────────────────────────

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(allProductsProvider).asData?.value ?? [];
    final orders   = ref.watch(adminOrdersProvider).asData?.value ?? [];
    final users    = ref.watch(allUsersProvider).asData?.value ?? [];

    final activeOrders    = orders.where((o) => o.orderStatus.isActive).length;
    final completedOrders = orders.where((o) => o.orderStatus == OrderStatus.completed).length;
    final revenue = orders
        .where((o) => o.orderStatus != OrderStatus.cancelled)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allProductsProvider);
        ref.invalidate(adminOrdersProvider);
        ref.invalidate(allUsersProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        children: [
          // ── Stat row ──────────────────────────────────────
          Row(
            children: [
              _Stat(label: 'Revenue',  value: 'UGX ${NumberFormat.compact().format(revenue)}', icon: Icons.payments_outlined,       color: const Color(0xFF2E7D32)),
              _Stat(label: 'Products', value: '${products.length}',                             icon: Icons.inventory_2_outlined,     color: const Color(0xFF0984E3)),
              _Stat(label: 'Active',   value: '$activeOrders',                                  icon: Icons.local_shipping_outlined,  color: const Color(0xFFFDAA5E)),
              _Stat(label: 'Users',    value: '${users.length}',                                icon: Icons.people_outline,           color: const Color(0xFF6C5CE7)),
            ],
          ),
          const SizedBox(height: 10),

          // ── Quick actions ─────────────────────────────────
          _Section(
            title: 'Quick Actions',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChip(
                  label: 'Add Product',
                  icon: Icons.add,
                  color: const Color(0xFF2E7D32),
                  onTap: () => context.push('/admin/upload'),
                ),
                _ActionChip(
                  label: 'Sync Inventory',
                  icon: Icons.sync,
                  color: const Color(0xFF0984E3),
                  onTap: () => _runSync(context, ref, _SyncMode.all),
                ),
                _ActionChip(
                  label: 'Clean Duplicates',
                  icon: Icons.cleaning_services_outlined,
                  color: const Color(0xFFFF6B6B),
                  onTap: () => _runSync(context, ref, _SyncMode.cleanup),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Completion bar ────────────────────────────────
          _Section(
            title: 'Completion  $completedOrders / ${orders.length}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: orders.isEmpty ? 0 : completedOrders / orders.length,
                backgroundColor: const Color(0xFFE8ECE8),
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Recent orders ─────────────────────────────────
          _Section(
            title: 'Recent Orders',
            trailing: TextButton(
              onPressed: () => context.go('/admin/orders'),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View all', style: TextStyle(fontSize: 12)),
            ),
            child: orders.isEmpty
                ? const _Empty(message: 'No orders yet')
                : Column(
                    children: orders
                        .take(5)
                        .map((o) => _OrderRow(order: o))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _runSync(BuildContext context, WidgetRef ref, _SyncMode mode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      switch (mode) {
        case _SyncMode.all:     await DataSetupService.initializeInventory(); break;
        case _SyncMode.special: await DataSetupService.forceRepairSpecialized(); break;
        case _SyncMode.cleanup:
          await DataSetupService.cleanupAllDuplicates();
          await DataSetupService.initializeInventory();
          break;
      }
      ref.invalidate(allProductsProvider);
      ref.invalidate(adminOrdersProvider);
      for (final id in ['1', '2', '3', '4']) ref.invalidate(productsProvider(id));
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory updated successfully.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $error')),
      );
    }
  }
}

enum _SyncMode { all, special, cleanup }

// ─── Users Tab ───────────────────────────────────────────────────────────────

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    return usersAsync.when(
      data: (users) {
        final admins    = users.where((u) => u.role == 'admin').length;
        final riders    = users.where((u) => u.role == 'rider').length;
        final customers = users.where((u) => u.role == 'customer').length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          children: [
            Row(
              children: [
                _Stat(label: 'Total',     value: '${users.length}', icon: Icons.people_outline,              color: const Color(0xFF0984E3)),
                _Stat(label: 'Admins',    value: '$admins',          icon: Icons.admin_panel_settings_outlined, color: const Color(0xFF2E7D32)),
                _Stat(label: 'Riders',    value: '$riders',          icon: Icons.delivery_dining_outlined,    color: const Color(0xFF00B894)),
                _Stat(label: 'Customers', value: '$customers',       icon: Icons.person_outline,              color: const Color(0xFFFDAA5E)),
              ],
            ),
            const SizedBox(height: 10),
            if (users.isEmpty)
              const _Empty(message: 'No users found')
            else
              ...users.map((u) => _UserRow(user: u)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ─── Settings Tab ─────────────────────────────────────────────────────────────

class AdminSettingsTab extends StatelessWidget {
  const AdminSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('Settings coming soon', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

/// A compact stat tile — takes 1/4 of row width.
class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECE8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

/// A thin bordered section with title.
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 10, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A small chip-style action button.
class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Compact order row.
class _OrderRow extends StatelessWidget {
  final OrderModel order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(status.icon, color: status.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order ${order.shortId}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${order.totalItems} items · ${DateFormat.MMMd().add_jm().format(order.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          OrderStatusBadge(status: status, compact: true),
        ],
      ),
    );
  }
}

/// Compact user row.
class _UserRow extends StatelessWidget {
  final AppUser user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final color = switch (user.role) {
      'admin'  => const Color(0xFF2E7D32),
      'rider'  => const Color(0xFF00B894),
      _        => const Color(0xFF0984E3),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(Icons.person_outline, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ),
    );
  }
}
