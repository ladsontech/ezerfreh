import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderScreen extends ConsumerWidget {
  const RiderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(activeDeliveryOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        final outForDelivery = orders
            .where(
              (order) => order.status.toLowerCase() == 'out for delivery',
            )
            .length;
        final ready = orders
            .where(
              (order) => order.status.toLowerCase() == 'ready for pickup',
            )
            .length;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                final stats = [
                  _RiderStat(
                    label: 'Ready',
                    value: '$ready',
                    icon: Icons.storefront_outlined,
                    color: Colors.deepPurple,
                  ),
                  _RiderStat(
                    label: 'On Route',
                    value: '$outForDelivery',
                    icon: Icons.local_shipping_outlined,
                    color: Colors.teal,
                  ),
                  _RiderStat(
                    label: 'Active Jobs',
                    value: '${orders.length}',
                    icon: Icons.route_outlined,
                    color: Colors.orange,
                  ),
                ];

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWide ? 3 : 1,
                  childAspectRatio: isWide ? 3.2 : 4.4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: stats,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Delivery Queue',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (orders.isEmpty)
              const _NoDeliveries()
            else
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DeliveryCard(order: order),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _RiderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _RiderStat({
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
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
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

class _DeliveryCard extends StatelessWidget {
  final OrderModel order;

  const _DeliveryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final totalItems = order.items.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.id.substring(0, order.id.length < 8 ? order.id.length : 8).toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat.yMMMd().add_jm().format(order.createdAt)} - $totalItems items',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                order.items
                    .map((item) => '${item.quantity}x ${item.name}')
                    .join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _setStatus(context, 'Out for Delivery'),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Start'),
              ),
              if (order.latitude != null && order.longitude != null)
                FilledButton.tonalIcon(
                  onPressed: () => _launchNavigation(order.latitude!, order.longitude!),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Navigate'),
                ),
              FilledButton.icon(
                onPressed: () => _setStatus(context, 'Completed'),
                icon: const Icon(Icons.check),
                label: const Text('Complete'),
              ),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(28),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: details),
                const SizedBox(width: 16),
                actions,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [details, const SizedBox(height: 14), actions],
          );
        },
      ),
    );
  }

  Future<void> _setStatus(BuildContext context, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Order moved to $status')));
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final url = 'google.navigation:q=$lat,$lng';
    final fallbackUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
      await launchUrl(Uri.parse(fallbackUrl));
    }
  }
}

class _NoDeliveries extends StatelessWidget {
  const _NoDeliveries();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.local_shipping_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('No active deliveries right now.'),
        ],
      ),
    );
  }
}
