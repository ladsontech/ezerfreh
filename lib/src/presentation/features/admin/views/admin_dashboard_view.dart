import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/core/providers/user_provider.dart';
import 'package:ezer_fresh/src/core/services/data_setup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// The following widgets are now used as independent routes in the app router.


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
    final activeOrders = orders
        .where(
          (order) =>
              !['completed', 'cancelled'].contains(order.status.toLowerCase()),
        )
        .length;
    final revenue = orders
        .where((order) => order.status.toLowerCase() != 'cancelled')
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1120
                  ? 4
                  : (constraints.maxWidth >= 620 ? 2 : 1);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.85,
                children: [
                  _StatCard(
                    title: 'Products',
                    value: '${products.length}',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Active Orders',
                    value: '$activeOrders',
                    icon: Icons.local_shipping_outlined,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Revenue',
                    value: 'UGX ${NumberFormat.compact().format(revenue)}',
                    icon: Icons.payments_outlined,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Users',
                    value: '${users.length}',
                    icon: Icons.people_outline,
                    color: Colors.purple,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Text(
                'Quick Actions',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.push('/admin/upload'),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ActionTile(
                title: 'Sync Complete Shop',
                subtitle: 'Bulk upload all inventory',
                icon: Icons.sync,
                color: Colors.purple,
                onTap: () => _handleSync(context, ref, 'all'),
              ),
              _ActionTile(
                title: 'Repair Herbs & Spices',
                subtitle: 'Clean categories 3 and 4',
                icon: Icons.eco_outlined,
                color: Colors.teal,
                onTap: () => _handleSync(context, ref, 'special'),
              ),
              _ActionTile(
                title: 'Clean Duplicates',
                subtitle: 'Remove redundant products',
                icon: Icons.cleaning_services_outlined,
                color: Colors.red,
                onTap: () => _handleSync(context, ref, 'cleanup'),
              ),
            ],
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
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Syncing Inventory...'),
                Text('This may take a minute', style: TextStyle(fontSize: 12)),
              ],
            ),
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
          const SnackBar(content: Text('Inventory sync successful.')),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }
}

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8ECE8)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF7FAF6),
                  ),
                  columns: const [
                    DataColumn(label: Text('NAME')),
                    DataColumn(label: Text('EMAIL')),
                    DataColumn(label: Text('ROLE')),
                    DataColumn(label: Text('JOINED')),
                  ],
                  rows: users
                      .map(
                        (user) => DataRow(
                          cells: [
                            DataCell(Text(user.name)),
                            DataCell(Text(user.email)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(user.role).withAlpha(26),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  user.role.toUpperCase(),
                                  style: TextStyle(
                                    color: _getRoleColor(user.role),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                user.createdAt != null
                                    ? DateFormat.yMMMd().format(user.createdAt!)
                                    : 'N/A',
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'rider':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

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
