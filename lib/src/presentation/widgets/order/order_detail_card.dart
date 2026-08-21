import 'package:ezer_fresh/src/domain/models/order_model.dart';
import 'package:ezer_fresh/src/presentation/widgets/order/order_status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Single source of truth for "everything there is to know about an order,"
/// shown identically to riders and admins. Each screen supplies its own
/// [footer] for role-specific controls (a rider's "next step" button vs. an
/// admin's status + rider-assignment controls) — the information above the
/// footer never differs between roles.
class OrderDetailCard extends StatefulWidget {
  final OrderModel order;

  /// Resolved display name/phone of the assigned rider, if any. Callers
  /// look this up (e.g. from a users list) since this widget doesn't know
  /// about user records — pass null while unresolved or unassigned.
  final String? assignedRiderLabel;

  /// Whether the itemized product list starts expanded. Riders usually
  /// need to see it immediately; admins scanning many orders may prefer it
  /// collapsed behind the summary line.
  final bool itemsExpandedByDefault;

  /// Role-specific action controls rendered below a divider, e.g. a
  /// rider's "Mark Picked Up" button or an admin's status/rider pickers.
  final Widget? footer;

  const OrderDetailCard({
    super.key,
    required this.order,
    this.assignedRiderLabel,
    this.itemsExpandedByDefault = true,
    this.footer,
  });

  @override
  State<OrderDetailCard> createState() => _OrderDetailCardState();
}

class _OrderDetailCardState extends State<OrderDetailCard> {
  late bool _itemsExpanded = widget.itemsExpandedByDefault;
  bool _opening = false;

  Future<void> _callCustomer(String phone) async {
    try {
      await launchUrl(Uri(scheme: 'tel', path: phone));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open dialer.')));
    }
  }

  Future<void> _openInMaps() async {
    final lat = widget.order.latitude;
    final lng = widget.order.longitude;
    if (lat == null || lng == null) return;

    setState(() => _opening = true);
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
      ).showSnackBar(SnackBar(content: Text('Could not open maps: $error')));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.orderStatus;

    return Container(
      decoration: OrderPanelDecoration.card(
        borderColor: status.color.withValues(alpha: 0.22),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      order.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.shortId} · ${DateFormat.yMMMd().add_jm().format(order.createdAt)}',
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
          const SizedBox(height: 12),
          OrderDeliveryTimeline(status: status, compact: true),

          if (order.hasContactInfo ||
              (order.customerEmail?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.phone_outlined,
              trailing: order.hasContactInfo
                  ? TextButton.icon(
                      onPressed: () => _callCustomer(order.customerPhone!),
                      icon: const Icon(Icons.call, size: 14),
                      label: const Text('Call'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  : null,
              child: Text(
                order.customerPhone!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (order.customerEmail?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.email_outlined,
                child: Text(
                  order.customerEmail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ],

          if (order.address != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on_outlined,
              child: Text(
                order.address!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            if (order.apartmentSuite?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.apartment_outlined,
                child: Text(
                  order.apartmentSuite!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
            if (order.hasLocation) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: OutlinedButton.icon(
                  onPressed: _opening ? null : _openInMaps,
                  icon: const Icon(Icons.map_outlined, size: 14),
                  label: Text(_opening ? 'Opening…' : 'Open in Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    minimumSize: const Size(0, 34),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],

          if (widget.assignedRiderLabel != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.delivery_dining_outlined,
              child: Text(
                'Rider: ${widget.assignedRiderLabel}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],

          const SizedBox(height: 12),
          InkWell(
            onTap: () => setState(() => _itemsExpanded = !_itemsExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order.totalItems} item${order.totalItems == 1 ? '' : 's'} · UGX ${NumberFormat('#,##0').format(order.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    _itemsExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_itemsExpanded) ...[
            const SizedBox(height: 4),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'UGX ${NumberFormat('#,##0').format(item.price * item.quantity)}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (widget.footer != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            widget.footer!,
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _InfoRow({required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: child),
        if (trailing != null) trailing!,
      ],
    );
  }
}
