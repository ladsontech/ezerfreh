import 'package:cached_network_image/cached_network_image.dart';
import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _EmptyCustomerOrders(onShop: () => context.go('/home'));
          }

          final products = productsAsync.asData?.value ?? [];
          final imageMap = {for (final p in products) p.id: p.imageUrl};

          final activeOrders =
              orders.where((o) => o.orderStatus.isActive).toList();
          final historyOrders =
              orders.where((o) => o.orderStatus.isTerminal).toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8ECE8)),
                  ),
                  child: TabBar(
                    labelColor: const Color(0xFF2E7D32),
                    unselectedLabelColor: Colors.grey[600],
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: const Color(0xFF2E7D32),
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.lato(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 18),
                            const SizedBox(width: 6),
                            Text('Active (${activeOrders.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history, size: 18),
                            const SizedBox(width: 6),
                            Text('History (${historyOrders.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Active Orders Tab
                      activeOrders.isEmpty
                          ? _EmptyTabContent(
                              icon: Icons.local_shipping_outlined,
                              title: 'No active orders',
                              subtitle:
                                  'Your pending and in-progress orders will appear here.',
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                ref.watch(cartProvider).isNotEmpty
                                    ? 180.0
                                    : 24.0,
                              ),
                              itemCount: activeOrders.length,
                              itemBuilder: (context, index) =>
                                  _CustomerOrderCard(
                                order: activeOrders[index],
                                imageMap: imageMap,
                              ),
                            ),

                      // History Tab
                      historyOrders.isEmpty
                          ? _EmptyTabContent(
                              icon: Icons.history,
                              title: 'No order history',
                              subtitle:
                                  'Completed and cancelled orders will show up here.',
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                ref.watch(cartProvider).isNotEmpty
                                    ? 180.0
                                    : 24.0,
                              ),
                              itemCount: historyOrders.length,
                              itemBuilder: (context, index) =>
                                  _CustomerHistoryCard(
                                order: historyOrders[index],
                                imageMap: imageMap,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  final OrderModel order;
  final Map<String, String> imageMap;

  const _CustomerOrderCard({required this.order, required this.imageMap});

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: status.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(status.icon, color: status.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.items.map((i) => i.name).take(2).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${order.shortId} · ${DateFormat.yMMMd().add_jm().format(order.createdAt)}',
                      style: GoogleFonts.lato(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              OrderStatusBadge(status: status, compact: true),
            ],
          ),

          const SizedBox(height: 10),
          OrderDeliveryTimeline(status: status, compact: true),

          // Product images row
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  final imgUrl = imageMap[item.productId] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: const Color(0xFFE8ECE8)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildItemImage(imgUrl),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 8),
          // Items list
          ...order.items.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.name}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      Text(
                        'UGX ${NumberFormat('#,##0').format(item.price * item.quantity)}',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
          if (order.items.length > 3)
            Text(
              '+${order.items.length - 3} more items',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),

          const Divider(height: 16),
          Row(
            children: [
              Text('Total',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const Spacer(),
              Text(
                'UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerHistoryCard extends StatefulWidget {
  final OrderModel order;
  final Map<String, String> imageMap;

  const _CustomerHistoryCard({required this.order, required this.imageMap});

  @override
  State<_CustomerHistoryCard> createState() => _CustomerHistoryCardState();
}

class _CustomerHistoryCardState extends State<_CustomerHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final imageMap = widget.imageMap;
    final status = order.orderStatus;
    final isCompleted = status == OrderStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Product image thumbnail
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: order.items.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildItemImage(
                                imageMap[order.items.first.productId] ?? ''),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shopping_basket_outlined,
                                size: 20, color: Color(0xFFA5D6A7)),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items.map((i) => i.name).take(2).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${order.shortId} · ${order.totalItems} items · ${DateFormat.yMMMd().format(order.createdAt)}',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                        style: GoogleFonts.lato(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isCompleted
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFFF6B6B))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCompleted ? 'Delivered' : 'Cancelled',
                          style: TextStyle(
                            color: isCompleted
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFFF6B6B),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),

              // Expanded details panel
              if (_expanded) ...[
                const Divider(height: 20),
                if (order.address != null && order.address!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.fullAddress ?? order.address!,
                          style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Order Details',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE8ECE8)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _buildItemImage(imageMap[item.productId] ?? ''),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${item.quantity} x UGX ${NumberFormat('#,##0').format(item.price)}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'UGX ${NumberFormat('#,##0').format(item.price * item.quantity)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700]),
                    ),
                    Text(
                      'UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTabContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyTabContent({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8ECE8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
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
          borderRadius: BorderRadius.circular(10),
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
            Text(
              'No orders yet',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
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

Widget _buildItemImage(String imageUrl) {
  final url = imageUrl.trim();
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.grey[100]),
      errorWidget: (_, __, ___) =>
          const Icon(Icons.broken_image, size: 16),
    );
  }
  if (url.isNotEmpty) {
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.image_not_supported, size: 16),
    );
  }
  return Container(
    color: const Color(0xFFF1F8F1),
    child: const Icon(
      Icons.shopping_basket_outlined,
      size: 16,
      color: Color(0xFFA5D6A7),
    ),
  );
}
