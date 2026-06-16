import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ─── Overview Tab ────────────────────────────────────────────────────────────

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(allProductsProvider).asData?.value ?? [];
    final orders = ref.watch(adminOrdersProvider).asData?.value ?? [];
    final users = ref.watch(allUsersProvider).asData?.value ?? [];

    final activeOrders = orders.where((o) => o.orderStatus.isActive).length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allProductsProvider);
        ref.invalidate(adminOrdersProvider);
        ref.invalidate(allUsersProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // ── Welcome card ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your products, orders, and user directory from one place.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Admin Features & Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 10),

          // ── Features Grid (Stat Cards acting as Nav Buttons) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 3 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 1.4 : 3.2,
                children: [
                  _FeatureCard(
                    title: 'Inventory & Products',
                    stat: '${products.length} Products',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF2E7D32),
                    onTap: () => context.go('/admin/products'),
                  ),
                  _FeatureCard(
                    title: 'Customer Orders',
                    stat: '${orders.length} Total ($activeOrders Active)',
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFF0984E3),
                    onTap: () => context.push('/admin/orders'),
                  ),
                  _FeatureCard(
                    title: 'User Management',
                    stat: '${users.length} Users registered',
                    icon: Icons.people_outline,
                    color: const Color(0xFF6C5CE7),
                    onTap: () => context.push('/admin/users'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Quick Actions ──────────────────────────────────
          _Section(
            title: 'Quick Actions',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChip(
                  label: 'Add New Product',
                  icon: Icons.add,
                  color: const Color(0xFF2E7D32),
                  onTap: () => context.push('/admin/upload'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final String title;
  final String stat;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.stat,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECE8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
