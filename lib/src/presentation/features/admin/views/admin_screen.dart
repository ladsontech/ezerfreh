import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/admin_orders_screen.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/admin_products_list_screen.dart';
import 'package:ezer_fresh/src/presentation/features/admin/views/upload_product_screen.dart';
import 'package:ezer_fresh/src/core/services/data_setup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAdminCard(
              context,
              'Upload Product',
              'Add fresh inventory to the shop',
              Icons.add_shopping_cart,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadProductScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              'Manage Products',
              'Edit or remove existing items',
              Icons.inventory_2_outlined,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProductsListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              'View All Orders',
              'Track customer purchases and status',
              Icons.receipt_long_outlined,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminOrdersScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              'Initialize Inventory',
              'One-time bulk upload of full inventory',
              Icons.system_update_alt,
              Colors.purple,
              () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  await DataSetupService.initializeInventory();
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Inventory Initialized Successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Upload failed: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              'Database Diagnostics',
              'Check real-time product counts',
              Icons.analytics_outlined,
              Colors.teal,
              () => _showCategoryStats(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryStats(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Stats',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Vegetables (ID: 1)'),
            _buildStatRow('Fruits (ID: 2)'),
            _buildStatRow('Herbs (ID: 3)'),
            _buildStatRow('Spices (ID: 4)'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label) {
    final parts = label.split('ID: ');
    final catId = parts[1].replaceAll(')', '');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('categoryId', isEqualTo: catId)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '$count items',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(26),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
