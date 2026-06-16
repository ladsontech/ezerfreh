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

  static const _filters = [
    'All',
    'Active',
    'Ready for Pickup',
    'Assigned',
    'On Route',
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(riderOrdersProvider);
    final riderId = ref.watch(authServiceProvider).currentUser?.uid;

    return ordersAsync.when(
      data: (orders) {
        final filtered = _filterOrders(orders);
        final ready = orders
            .where((order) => order.orderStatus == OrderStatus.readyForPickup)
            .length;
        final assigned = orders
            .where((order) => order.orderStatus == OrderStatus.assigned)
            .length;
        final onRoute = orders
            .where(
              (order) =>
                  order.orderStatus == OrderStatus.pickedUp ||
                  order.orderStatus == OrderStatus.onTheWay ||
                  order.orderStatus == OrderStatus.arrived,
            )
            .length;
        final active = orders.where((order) => order.orderStatus.isActive).length;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(riderOrdersProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _RiderHeader(active: active, ready: ready, onRoute: onRoute),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760 ? 4 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: columns == 4 ? 2.4 : 1.8,
                    children: [
                      _RiderStat(label: 'Active', value: '$active', icon: Icons.bolt_outlined),
                      _RiderStat(label: 'Ready', value: '$ready', icon: Icons.storefront_outlined),
                      _RiderStat(label: 'Assigned', value: '$assigned', icon: Icons.assignment_ind_outlined),
                      _RiderStat(label: 'On Route', value: '$onRoute', icon: Icons.navigation_outlined),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Delivery Queue',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const LiveIndicator(),
                ],
              ),
              const SizedBox(height: 12),
              OrderStatusChipBar(
                selected: _filter,
                options: _filters,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                const _EmptyDeliveries()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    if (!wide) {
                      return Column(
                        children: filtered
                            .map((order) => _RiderOrderCard(
                                  order: order,
                                  riderId: riderId,
                                ))
                            .toList(),
                      );
                    }

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: filtered
                          .map(
                            (order) => SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: _RiderOrderCard(
                                order: order,
                                riderId: riderId,
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

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    return switch (_filter) {
      'All' => orders,
      'Active' => orders.where((order) => order.orderStatus.isActive).toList(),
      'Ready for Pickup' => orders
          .where((order) => order.orderStatus == OrderStatus.readyForPickup)
          .toList(),
      'Assigned' => orders
          .where((order) => order.orderStatus == OrderStatus.assigned)
          .toList(),
      'On Route' => orders
          .where(
            (order) =>
                order.orderStatus == OrderStatus.pickedUp ||
                order.orderStatus == OrderStatus.onTheWay ||
                order.orderStatus == OrderStatus.arrived,
          )
          .toList(),
      _ => orders,
    };
  }
}

class _RiderHeader extends StatelessWidget {
  final int active;
  final int ready;
  final int onRoute;

  const _RiderHeader({
    required this.active,
    required this.ready,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF00B894).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delivery_dining, color: Color(0xFF00B894)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  onRoute > 0 ? 'Deliveries in Progress' : 'Ready for Deliveries',
                  style: GoogleFonts.lato(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$active active, $ready ready, $onRoute on route',
                  style: GoogleFonts.lato(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RiderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B894)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(label, style: GoogleFonts.lato(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final String? riderId;

  const _RiderOrderCard({required this.order, required this.riderId});

  @override
  ConsumerState<_RiderOrderCard> createState() => _RiderOrderCardState();
}

class _RiderOrderCardState extends ConsumerState<_RiderOrderCard> {
  bool _updating = false;
  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.orderStatus;
    final nextStatus = status.nextRiderStatus;
    final nextAction = status.nextRiderActionLabel;
    final canAdvance = nextStatus != null && nextAction != null && !status.isTerminal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(borderColor: status.color.withValues(alpha: 0.22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(status.icon, color: status.color),
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
                      DateFormat.yMMMd().add_jm().format(order.createdAt),
                      style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              OrderStatusBadge(status: status, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          OrderDeliveryTimeline(status: status),
          const SizedBox(height: 12),
          Text(
            order.items.map((item) => '${item.quantity}x ${item.name}').join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${order.totalItems} items, UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
            style: GoogleFonts.lato(fontWeight: FontWeight.w800),
          ),
          if (order.fullAddress != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.fullAddress!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canAdvance)
                FilledButton.icon(
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
                ),
              if (order.hasLocation)
                OutlinedButton.icon(
                  onPressed: _navigating ? null : _openNavigation,
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: Text(_navigating ? 'Opening...' : 'Navigate'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _advanceStatus() async {
    final riderId = widget.riderId;
    if (riderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to update deliveries.')),
      );
      return;
    }

    final next = widget.order.orderStatus.nextRiderStatus;
    setState(() => _updating = true);
    try {
      await ref.read(orderServiceProvider).advanceRiderStatus(
            orderId: widget.order.id,
            current: widget.order.orderStatus,
            riderId: riderId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${widget.order.shortId} updated to ${next?.label ?? 'next status'}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _openNavigation() async {
    final lat = widget.order.latitude;
    final lng = widget.order.longitude;
    if (lat == null || lng == null) return;

    setState(() => _navigating = true);
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
      'travelmode': 'driving',
    });

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }
}

class _EmptyDeliveries extends StatelessWidget {
  const _EmptyDeliveries();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            'No deliveries in this view',
            style: GoogleFonts.lato(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Orders update here automatically.',
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
