import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/data/services/order_service.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_detail_card.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Simplified, clean rider dashboard. Every order card is the shared
/// [OrderDetailCard] — the exact same widget the admin Orders screen uses —
/// so a rider always sees the full picture (contact info, address, items,
/// timeline) with just a single guided "next step" action below it.
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
      data: (allOrders) {
        final orders = allOrders
            .where((order) => !order.orderStatus.isTerminal)
            .toList();
        final filtered = _filterOrders(orders);
        final ready = orders
            .where((order) => order.orderStatus == OrderStatus.readyForPickup)
            .length;
        final onRoute = orders.where(_isOnRoute).length;
        final active = orders
            .where((order) => order.orderStatus.isActive)
            .length;

        return RefreshIndicator(
          color: const Color(0xFF00B894),
          onRefresh: () async => ref.invalidate(riderOrdersProvider),
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
                      _RiderSummaryPanel(
                        active: active,
                        ready: ready,
                        onRoute: onRoute,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Delivery Queue',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const LiveIndicator(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OrderStatusChipBar(
                        selected: _filter,
                        options: _filters,
                        onSelected: (value) => setState(() => _filter = value),
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        const _EmptyDeliveries()
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cards = filtered
                                .map(
                                  (order) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: OrderDetailCard(
                                      order: order,
                                      itemsExpandedByDefault: false,
                                      footer: _RiderCardFooter(
                                        order: order,
                                        riderId: riderId,
                                      ),
                                    ),
                                  ),
                                )
                                .toList();

                            final wide = constraints.maxWidth >= 920;
                            if (!wide) return Column(children: cards);

                            return Wrap(
                              spacing: 12,
                              children: cards
                                  .map(
                                    (card) => SizedBox(
                                      width: (constraints.maxWidth - 12) / 2,
                                      child: card,
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

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    return switch (_filter) {
      'All' => orders,
      'Active' => orders.where((order) => order.orderStatus.isActive).toList(),
      'Ready for Pickup' =>
        orders
            .where((order) => order.orderStatus == OrderStatus.readyForPickup)
            .toList(),
      'Assigned' =>
        orders
            .where((order) => order.orderStatus == OrderStatus.assigned)
            .toList(),
      'On Route' => orders.where(_isOnRoute).toList(),
      _ => orders,
    };
  }

  bool _isOnRoute(OrderModel order) {
    return order.orderStatus == OrderStatus.pickedUp ||
        order.orderStatus == OrderStatus.onTheWay ||
        order.orderStatus == OrderStatus.arrived;
  }
}

class _RiderSummaryPanel extends StatelessWidget {
  final int active;
  final int ready;
  final int onRoute;

  const _RiderSummaryPanel({
    required this.active,
    required this.ready,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF00B894).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Color(0xFF00B894),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  onRoute > 0 ? 'Deliveries in Progress' : 'Ready for Work',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$active active · $ready ready · $onRoute on route',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

/// Renders the rider's single guided "next step" for an order. The
/// [OrderDetailCard] above already shows an "Open in Maps" button whenever
/// the order has coordinates, so this footer only needs the status-advance
/// button — no redundant raw status dropdown.
class _RiderCardFooter extends ConsumerStatefulWidget {
  final OrderModel order;
  final String? riderId;

  const _RiderCardFooter({required this.order, required this.riderId});

  @override
  ConsumerState<_RiderCardFooter> createState() => _RiderCardFooterState();
}

class _RiderCardFooterState extends ConsumerState<_RiderCardFooter> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.order.orderStatus;
    final nextStatus = status.nextRiderStatus;
    final nextAction = status.nextRiderActionLabel;
    if (nextStatus == null || nextAction == null || status.isTerminal) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _updating ? null : _advance,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF00B894),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        icon: _updating
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(nextStatus.icon, size: 16),
        label: Text(nextAction, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Future<void> _advance() async {
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
      await ref
          .read(orderServiceProvider)
          .advanceRiderStatus(
            orderId: widget.order.id,
            current: widget.order.orderStatus,
            riderId: riderId,
          );
      if (!mounted) return;

      if (next == OrderStatus.completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order delivered successfully.'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        context.go('/rider/history');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order status updated to ${next?.label ?? 'next status'}.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $error')));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

class _EmptyDeliveries extends StatelessWidget {
  const _EmptyDeliveries();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No deliveries in this view',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Orders update here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
