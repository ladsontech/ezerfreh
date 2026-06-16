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

// ─── Admin Overview Tab (Dashboard) ─────────────────────────────────────────

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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Revenue Banner ──
          _RevenueBanner(
            revenue: revenue,
            totalOrders: orders.length,
            completedOrders: completedOrders,
          ),
          const SizedBox(height: 20),

          // ── Stat Cards Grid ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 2.2 : 1.5,
                children: [
                  _StatCard(
                    title: 'Products',
                    value: '${products.length}',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF2E7D32),
                  ),
                  _StatCard(
                    title: 'Active Orders',
                    value: '$activeOrders',
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFFFDAA5E),
                  ),
                  _StatCard(
                    title: 'Completed',
                    value: '$completedOrders',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF4CAF50),
                  ),
                  _StatCard(
                    title: 'Users',
                    value: '${users.length}',
                    icon: Icons.people_outline,
                    color: const Color(0xFF0984E3),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Quick Actions ──
          Row(
            children: [
              Text(
                'Quick Actions',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _PillButton(
                label: 'Add Product',
                icon: Icons.add,
                color: const Color(0xFF2E7D32),
                onTap: () => context.push('/admin/upload'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionTile(
                title: 'Sync Inventory',
                subtitle: 'Bulk upload all products',
                icon: Icons.sync,
                color: const Color(0xFF2E7D32),
                onTap: () => _handleSync(context, ref, 'all'),
              ),
              _ActionTile(
                title: 'Repair Categories',
                subtitle: 'Fix herbs & spices data',
                icon: Icons.eco_outlined,
                color: const Color(0xFF00B894),
                onTap: () => _handleSync(context, ref, 'special'),
              ),
              _ActionTile(
                title: 'Clean Duplicates',
                subtitle: 'Remove redundant items',
                icon: Icons.cleaning_services_outlined,
                color: const Color(0xFFFF6B6B),
                onTap: () => _handleSync(context, ref, 'cleanup'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Recent Orders ──
          Row(
            children: [
              Text(
                'Recent Orders',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/admin/orders'),
                child: Text(
                  'View all →',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            _EmptySection(
              icon: Icons.receipt_long_outlined,
              message: 'No orders yet',
            )
          else
            ...orders.take(5).map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RecentOrderCard(order: order),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _handleSync(
    BuildContext context,
    WidgetRef ref,
    String mode,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2E7D32)),
              const SizedBox(height: 16),
              Text(
                'Syncing Inventory...',
                style: GoogleFonts.lato(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'This may take a minute',
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      if (mode == 'all') {
        await DataSetupService.initializeInventory();
      } else if (mode == 'cleanup') {
        await DataSetupService.cleanupAllDuplicates();
        await DataSetupService.initializeInventory();
      } else {
        await DataSetupService.forceRepairSpecialized();
      }

      if (context.mounted) Navigator.pop(context);

      ref.invalidate(allProductsProvider);
      for (final id in ['1', '2', '3', '4']) {
        ref.invalidate(productsProvider(id));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Inventory sync successful.'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }
}

// ─── Revenue Banner ─────────────────────────────────────────────────────────

class _RevenueBanner extends StatelessWidget {
  final double revenue;
  final int totalOrders;
  final int completedOrders;

  const _RevenueBanner({
    required this.revenue,
    required this.totalOrders,
    required this.completedOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Revenue',
                    style: GoogleFonts.lato(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'UGX ${NumberFormat('#,###').format(revenue)}',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _BannerChip(
                label: 'Total Orders',
                value: '$totalOrders',
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(width: 12),
              _BannerChip(
                label: 'Completed',
                value: '$completedOrders',
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 12),
              _BannerChip(
                label: 'Completion',
                value: totalOrders > 0
                    ? '${(completedOrders / totalOrders * 100).toStringAsFixed(0)}%'
                    : '0%',
                icon: Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BannerChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.lato(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Tile ────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pill Button ────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent Order Card ──────────────────────────────────────────────────────

class _RecentOrderCard extends StatelessWidget {
  final OrderModel order;

  const _RecentOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus;
    final statusColor = status.color;
    final totalItems =
        order.items.fold<int>(0, (int sum, item) => sum + item.quantity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(status.icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(0, order.id.length < 8 ? order.id.length : 8).toUpperCase()}',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$totalItems items • ${DateFormat.yMMMd().format(order.createdAt)}',
                  style: GoogleFonts.lato(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'UGX ${NumberFormat('#,###').format(order.totalAmount)}',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              OrderStatusBadge(status: status, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty Section ──────────────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.lato(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Users Tab ────────────────────────────────────────────────────────

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: _EmptySection(
              icon: Icons.people_outline,
              message: 'No users found.',
            ),
          );
        }

        final admins = users.where((u) => u.role == 'admin').length;
        final riders = users.where((u) => u.role == 'rider').length;
        final customers = users.where((u) => u.role == 'customer').length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── User Stats Row ──
            Row(
              children: [
                Expanded(
                  child: _UserStatChip(
                    label: 'Total',
                    value: '${users.length}',
                    color: const Color(0xFF0984E3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _UserStatChip(
                    label: 'Admins',
                    value: '$admins',
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _UserStatChip(
                    label: 'Riders',
                    value: '$riders',
                    color: const Color(0xFF00B894),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _UserStatChip(
                    label: 'Customers',
                    value: '$customers',
                    color: const Color(0xFFFDAA5E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── User List ──
            ...users.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _UserCard(user: user),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      ),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _UserStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _UserStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.lato(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;

  const _UserCard({required this.user});

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF2E7D32);
      case 'rider':
        return const Color(0xFF00B894);
      default:
        return const Color(0xFFFDAA5E);
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'rider':
        return Icons.delivery_dining_outlined;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user.role);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getRoleIcon(user.role), color: roleColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: GoogleFonts.lato(
                    color: roleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              if (user.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().format(user.createdAt!),
                  style: GoogleFonts.lato(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Admin Settings Tab ─────────────────────────────────────────────────────

class AdminSettingsTab extends StatelessWidget {
  const AdminSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECE8)),
        ),
        child: const Text('App settings coming soon.'),
      ),
    );
  }
}
