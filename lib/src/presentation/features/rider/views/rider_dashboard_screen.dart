import 'package:ezer_fresh/src/core/providers/order_provider.dart';
import 'package:ezer_fresh/src/core/providers/product_provider.dart';
import 'package:ezer_fresh/src/core/providers/providers.dart';
import 'package:ezer_fresh/src/data/services/order_service.dart';
import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final productsAsync = ref.watch(allProductsProvider);
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
        final assigned = orders
            .where((order) => order.orderStatus == OrderStatus.assigned)
            .length;
        final onRoute = orders.where(_isOnRoute).length;
        final active = orders
            .where((order) => order.orderStatus.isActive)
            .length;

        final products = productsAsync.asData?.value ?? [];
        final imageMap = {for (final p in products) p.id: p.imageUrl};

        return RefreshIndicator(
          color: const Color(0xFF00B894),
          onRefresh: () async {
            ref.invalidate(riderOrdersProvider);
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
                      _RiderSummaryPanel(
                        active: active,
                        ready: ready,
                        onRoute: onRoute,
                      ),
                      const SizedBox(height: 12),
                      _RiderStatsGrid(
                        stats: [
                          _RiderStatData(
                            label: 'Active',
                            value: '$active',
                            icon: Icons.bolt_outlined,
                          ),
                          _RiderStatData(
                            label: 'Ready',
                            value: '$ready',
                            icon: Icons.storefront_outlined,
                          ),
                          _RiderStatData(
                            label: 'Assigned',
                            value: '$assigned',
                            icon: Icons.assignment_ind_outlined,
                          ),
                          _RiderStatData(
                            label: 'On Route',
                            value: '$onRoute',
                            icon: Icons.navigation_outlined,
                          ),
                        ],
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
                            final wide = constraints.maxWidth >= 920;
                            if (!wide) {
                              return Column(
                                children: filtered
                                    .map(
                                      (order) => _RiderOrderCard(
                                        order: order,
                                        riderId: riderId,
                                        imageMap: imageMap,
                                      ),
                                    )
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
                  '$active active / $ready ready / $onRoute on route',
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

class _RiderStatsGrid extends StatelessWidget {
  final List<_RiderStatData> stats;

  const _RiderStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: width,
                  child: _RiderStat(data: stat),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _RiderStat extends StatelessWidget {
  final _RiderStatData data;

  const _RiderStat({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF00B894).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: const Color(0xFF00B894), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _RiderOrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final String? riderId;
  final Map<String, String> imageMap;

  const _RiderOrderCard({
    required this.order,
    required this.riderId,
    required this.imageMap,
  });

  @override
  ConsumerState<_RiderOrderCard> createState() => _RiderOrderCardState();
}

class _RiderOrderCardState extends ConsumerState<_RiderOrderCard> {
  bool _updating = false;
  bool _navigating = false;

  Future<void> _callCustomer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.orderStatus;
    final nextStatus = status.nextRiderStatus;
    final nextAction = status.nextRiderActionLabel;
    final canAdvance =
        nextStatus != null && nextAction != null && !status.isTerminal;
    final showActions = canAdvance || order.hasLocation;

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
                    // Customer name as primary identifier
                    Text(
                      order.displayName,
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
                      '${order.shortId} Â· ${DateFormat.yMMMd().add_jm().format(order.createdAt)}',
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

          // Customer contact section with call button
          if (order.hasContactInfo || (order.customerEmail?.isNotEmpty == true)) ...[
            const SizedBox(height: 10),
            _CustomerContactBar(
              phone: order.customerPhone,
              email: order.customerEmail,
              onCall: order.hasContactInfo ? () => _callCustomer(order.customerPhone!) : null,
            ),
          ],

          const SizedBox(height: 10),
          Text(
            order.items
                .map((item) => '${item.quantity}x ${item.name}')
                .join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 12,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          _OrderMetaWrap(order: order),
          if (!status.isTerminal) ...[
            const SizedBox(height: 12),
            _RiderStatusSelector(
              status: status,
              updating: _updating,
              onChanged: _updateStatus,
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 12),
            _RiderActions(
              canAdvance: canAdvance,
              updating: _updating,
              navigating: _navigating,
              hasLocation: order.hasLocation,
              nextStatus: nextStatus,
              nextAction: nextAction,
              onAdvance: _advanceStatus,
              onNavigate: _openNavigation,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(OrderStatus? status) async {
    if (status == null || status == widget.order.orderStatus) return;

    final riderId = widget.riderId;
    if (riderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to update deliveries.')),
      );
      return;
    }

    setState(() => _updating = true);
    try {
      await ref
          .read(orderServiceProvider)
          .updateStatus(widget.order.id, status, riderId: riderId);
      if (!mounted) return;

      if (status == OrderStatus.completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Order delivered successfully.',
            ),
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
              'Order status updated to ${status.label}.',
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
            content: const Text(
              'Order delivered successfully.',
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Navigation failed: $error')));
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }
}

/// Customer contact bar with call button for rider
class _CustomerContactBar extends StatelessWidget {
  final String? phone;
  final String? email;
  final VoidCallback? onCall;

  const _CustomerContactBar({
    required this.phone,
    required this.email,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (phone != null && phone!.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        phone!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                if (email != null && email!.isNotEmpty) ...[
                  if (phone != null && phone!.isNotEmpty) const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onCall != null)
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.call, size: 14),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RiderStatusSelector extends StatelessWidget {
  final OrderStatus status;
  final bool updating;
  final ValueChanged<OrderStatus?> onChanged;

  const _RiderStatusSelector({
    required this.status,
    required this.updating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<OrderStatus>(
      key: ValueKey(status),
      initialValue: status,
      decoration: InputDecoration(
        labelText: 'Update status',
        prefixIcon: const Icon(Icons.sync_alt_outlined, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: OrderStatus.adminFlow
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 16, color: item.color),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(item.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: updating ? null : onChanged,
    );
  }
}

// _ItemImageStrip was removed to simplify the order cards layout.

class _OrderMetaWrap extends StatelessWidget {
  final OrderModel order;

  const _OrderMetaWrap({required this.order});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaPill(
          icon: Icons.shopping_bag_outlined,
          text:
              '${order.totalItems} items / UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
        ),
        if (order.fullAddress != null)
          _MetaPill(
            icon: Icons.location_on_outlined,
            text: order.fullAddress!,
            wide: true,
          ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool wide;

  const _MetaPill({required this.icon, required this.text, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: wide ? 420 : 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECE8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
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

class _RiderActions extends StatelessWidget {
  final bool canAdvance;
  final bool updating;
  final bool navigating;
  final bool hasLocation;
  final OrderStatus? nextStatus;
  final String? nextAction;
  final VoidCallback onAdvance;
  final VoidCallback onNavigate;

  const _RiderActions({
    required this.canAdvance,
    required this.updating,
    required this.navigating,
    required this.hasLocation,
    required this.nextStatus,
    required this.nextAction,
    required this.onAdvance,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (!canAdvance && !hasLocation) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 380;
        final buttons = <Widget>[
          if (canAdvance)
            _ActionButtonShell(
              expand: stacked,
              child: FilledButton.icon(
                onPressed: updating ? null : onAdvance,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00B894),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: updating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(nextStatus?.icon ?? Icons.check, size: 15),
                label: Text(
                  nextAction ?? 'Update',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (hasLocation)
            _ActionButtonShell(
              expand: stacked,
              child: OutlinedButton.icon(
                onPressed: navigating ? null : onNavigate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00B894),
                  side: const BorderSide(color: Color(0xFF00B894)),
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.navigation_outlined, size: 15),
                label: Text(
                  navigating ? 'Opening...' : 'Navigate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ];

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                buttons[i],
                if (i != buttons.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              Expanded(child: buttons[i]),
              if (i != buttons.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _ActionButtonShell extends StatelessWidget {
  final bool expand;
  final Widget child;

  const _ActionButtonShell({required this.expand, required this.child});

  @override
  Widget build(BuildContext context) {
    if (expand) return SizedBox(width: double.infinity, child: child);
    return child;
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

class _RiderStatData {
  final String label;
  final String value;
  final IconData icon;

  const _RiderStatData({
    required this.label,
    required this.value,
    required this.icon,
  });
}

// _buildItemImage was removed because item image strip was removed from rider cards.

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

