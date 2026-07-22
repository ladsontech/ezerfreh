import 'package:cached_network_image/cached_network_image.dart';
import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          color: const Color(0xFF00B894),
          onRefresh: () async {
            ref.invalidate(riderHistoryProvider);
            await refreshProductsCatalog(ref);
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
                      _HistoryHeader(
                        completed: completed,
                        cancelled: cancelled,
                        orderValue: orderValue,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Past Deliveries',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${orders.length} total',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (orders.isEmpty)
                        const _EmptyHistory()
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 920;
                            if (!wide) {
                              return Column(
                                children: orders
                                    .map(
                                      (order) => _HistoryTile(
                                        order: order,
                                        imageMap: imageMap,
                                      ),
                                    )
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
                ),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF00B894),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delivery History',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const LiveIndicator(),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECE8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        borderColor: status.color.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(status.icon, color: status.color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${order.shortId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.totalItems} items / ${DateFormat.yMMMd().format(order.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OrderStatusBadge(status: status, compact: true),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                label: 'Value',
                value: 'UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
              ),
              if (order.fullAddress != null)
                _AddressPill(address: order.fullAddress!),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ItemImageStrip(order: order, imageMap: imageMap),
          ],
        ],
      ),
    );
  }
}

class _AddressPill extends StatelessWidget {
  final String address;

  const _AddressPill({required this.address});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECE8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemImageStrip extends StatelessWidget {
  final OrderModel order;
  final Map<String, String> imageMap;

  const _ItemImageStrip({required this.order, required this.imageMap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: order.items.length,
        itemBuilder: (context, index) {
          final item = order.items[index];
          final imageUrl = imageMap[item.productId] ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE8ECE8)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildItemImage(imageUrl),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
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
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.history, size: 44, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            'No delivery history yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed and cancelled deliveries will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
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
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 14),
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
