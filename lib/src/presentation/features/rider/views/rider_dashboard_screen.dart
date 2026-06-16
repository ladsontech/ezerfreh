import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/data/services/order_service.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  String _filter = 'Active';

  static const _filters = ['All', 'Active', 'Assigned', 'On the Way', 'Done'];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(riderOrdersProvider);
    final user = ref.watch(authServiceProvider).currentUser;

    return ordersAsync.when(
      data: (orders) {
        final filtered = _filterOrders(orders);
        final active = orders.where((o) => o.orderStatus.isActive).length;
        final assigned = orders
            .where((o) => o.orderStatus == OrderStatus.assigned)
            .length;
        final onTheWay = orders
            .where(
              (o) =>
                  o.orderStatus == OrderStatus.onTheWay ||
                  o.orderStatus == OrderStatus.arrived,
            )
            .length;

        return RefreshIndicator(
          color: const Color(0xFF00B894),
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _RiderHeroBanner(
                activeCount: active,
                onRouteCount: onTheWay,
                totalOrders: orders.length,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatTile(
                    label: 'Active',
                    value: '$active',
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFF00B894),
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    label: 'Assigned',
                    value: '$assigned',
                    icon: Icons.assignment_ind_outlined,
                    color: const Color(0xFF6C5CE7),
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    label: 'On Route',
                    value: '$onTheWay',
                    icon: Icons.navigation_outlined,
                    color: const Color(0xFF0984E3),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Orders',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const LiveIndicator(),
                ],
              ),
              const SizedBox(height: 12),
              OrderStatusChipBar(
                selected: _filter,
                options: _filters,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const _EmptyOrders()
              else
                ...filtered.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RiderOrderCard(
                      order: order,
                      riderId: user?.uid,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00B894)),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    return switch (_filter) {
      'All' => orders,
      'Active' => orders.where((o) => o.orderStatus.isActive).toList(),
      'Assigned' =>
        orders.where((o) => o.orderStatus == OrderStatus.assigned).toList(),
      'On the Way' => orders
          .where(
            (o) =>
                o.orderStatus == OrderStatus.onTheWay ||
                o.orderStatus == OrderStatus.arrived ||
                o.orderStatus == OrderStatus.pickedUp,
          )
          .toList(),
      'Done' => orders.where((o) => o.orderStatus.isTerminal).toList(),
      _ => orders,
    };
  }
}

class _RiderHeroBanner extends StatelessWidget {
  final int activeCount;
  final int onRouteCount;
  final int totalOrders;

  const _RiderHeroBanner({
    required this.activeCount,
    required this.onRouteCount,
    required this.totalOrders,
  });

  @override
  Widget build(BuildContext context) {
    final onRoute = onRouteCount > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onRoute
              ? [const Color(0xFF00B894), const Color(0xFF00CEC9)]
              : [const Color(0xFF2D3436), const Color(0xFF636E72)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (onRoute ? const Color(0xFF00B894) : const Color(0xFF2D3436))
                .withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              onRoute ? Icons.delivery_dining : Icons.two_wheeler,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  onRoute ? 'Deliveries in Progress' : 'Ready for Orders',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  onRoute
                      ? '$onRouteCount on route • $activeCount active total'
                      : '$totalOrders orders • $activeCount waiting',
                  style: GoogleFonts.lato(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
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

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: OrderPanelDecoration.card(borderColor: Colors.grey.shade100),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final String? riderId;

  const _RiderOrderCard({required this.order, this.riderId});

  @override
  ConsumerState<_RiderOrderCard> createState() => _RiderOrderCardState();
}

class _RiderOrderCardState extends ConsumerState<_RiderOrderCard> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.orderStatus;
    final nextStatus = status.nextRiderStatus;
    final nextAction = status.nextRiderActionLabel;
    final canAdvance = nextAction != null && nextStatus != null && !status.isTerminal;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: OrderPanelDecoration.card(
        borderColor: status.isActive
            ? status.color.withValues(alpha: 0.25)
            : const Color(0xFFE8ECE8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(status.icon, color: status.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${order.shortId}',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().add_jm().format(order.createdAt),
                      style: GoogleFonts.lato(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              OrderStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 14),
          OrderDeliveryTimeline(status: status),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  '${order.totalItems} items • UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (order.fullAddress != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.fullAddress!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (canAdvance || order.hasLocation) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (canAdvance)
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _updating ? null : _advanceStatus,
                      icon: _updating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(nextStatus.icon, size: 18),
                      label: Text(nextAction),
                      style: FilledButton.styleFrom(
                        backgroundColor: nextStatus.color,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (canAdvance && order.hasLocation) const SizedBox(width: 8),
                if (order.hasLocation)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launchNavigation(
                        order.latitude!,
                        order.longitude!,
                      ),
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text('Navigate'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _advanceStatus() async {
    if (widget.riderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to update orders')),
      );
      return;
    }

    setState(() => _updating = true);
    try {
      await ref.read(orderServiceProvider).advanceRiderStatus(
            orderId: widget.order.id,
            current: widget.order.orderStatus,
            riderId: widget.riderId!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated to ${widget.order.orderStatus.nextRiderStatus?.label ?? 'new status'}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final url = 'google.navigation:q=$lat,$lng';
    final fallbackUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
      await launchUrl(Uri.parse(fallbackUrl));
    }
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: OrderPanelDecoration.card(),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No orders in this view',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Orders update instantly as they come in.',
            style: GoogleFonts.lato(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
