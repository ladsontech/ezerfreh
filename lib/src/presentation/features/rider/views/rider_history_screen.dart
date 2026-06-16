import 'package:cached_network_image/cached_network_image.dart';
import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RiderHistoryScreen extends ConsumerWidget {
  const RiderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(riderHistoryProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return historyAsync.when(
      data: (orders) {
        final completed = orders
            .where((order) => order.orderStatus == OrderStatus.completed)
            .length;
        final cancelled = orders
            .where((order) => order.orderStatus == OrderStatus.cancelled)
            .length;
        final orderValue = orders
            .where((order) => order.orderStatus == OrderStatus.completed)
            .fold<double>(0, (sum, order) => sum + order.totalAmount);

        final products = productsAsync.asData?.value ?? [];
        final imageMap = {for (final p in products) p.id: p.imageUrl};

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(riderHistoryProvider);
            ref.invalidate(allProductsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _HistoryHeader(
                completed: completed,
                cancelled: cancelled,
                orderValue: orderValue,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Past Deliveries',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text('${orders.length} total'),
                ],
              ),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                const _EmptyHistory()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    if (!wide) {
                      return Column(
                        children: orders
                            .map((order) => _HistoryTile(
                                  order: order,
                                  imageMap: imageMap,
                                ))
                            .toList(),
                      );
                    }

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: orders
                          .map(
                            (order) => SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: _HistoryTile(
                                order: order,
                                imageMap: imageMap,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final int completed;
  final int cancelled;
  final double orderValue;

  const _HistoryHeader({
    required this.completed,
    required this.cancelled,
    required this.orderValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF00B894)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivery History',
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const LiveIndicator(),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryPill(label: 'Completed', value: '$completed'),
              _SummaryPill(label: 'Cancelled', value: '$cancelled'),
              _SummaryPill(
                label: 'Order Value',
                value: 'UGX ${NumberFormat.compact().format(orderValue)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECE8)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.lato(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final OrderModel order;
  final Map<String, String> imageMap;

  const _HistoryTile({required this.order, required this.imageMap});

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration:
          _cardDecoration(borderColor: status.color.withValues(alpha: 0.22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(status.icon, color: status.color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${order.shortId}',
                      style: GoogleFonts.lato(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${order.totalItems} items, ${DateFormat.yMMMd().format(order.createdAt)}',
                      style: GoogleFonts.lato(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  OrderStatusBadge(status: status, compact: true),
                ],
              ),
            ],
          ),

          // Product images row
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: const Color(0xFFE8ECE8)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
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
                                topLeft: Radius.circular(3),
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7.5,
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
        ],
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
          const Icon(Icons.broken_image, size: 14),
    );
  }
  if (url.isNotEmpty) {
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.image_not_supported, size: 14),
    );
  }
  return Container(
    color: const Color(0xFFF1F8F1),
    child: const Icon(
      Icons.shopping_basket_outlined,
      size: 14,
      color: Color(0xFFA5D6A7),
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            'No delivery history yet',
            style: GoogleFonts.lato(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed and cancelled deliveries will appear here.',
            style: GoogleFonts.lato(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color? borderColor}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor ?? const Color(0xFFE8ECE8)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}
