import 'package:ezer_fresh/src/domain/models/order_status.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveIndicator extends StatelessWidget {
  const LiveIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF00B894).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00B894).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(),
          const SizedBox(width: 6),
          Text(
            'Live',
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF00B894),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFF00B894),
              const Color(0xFF00B894).withValues(alpha: 0.35),
              _controller.value,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool compact;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: compact ? 12 : 14, color: status.color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 108 : 144),
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                color: status.color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDeliveryTimeline extends StatelessWidget {
  final OrderStatus status;
  final bool compact;

  const OrderDeliveryTimeline({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return OrderStatusBadge(status: status);
    }

    final steps = OrderStatus.deliveryFlow;
    final currentIndex = status.deliveryStepIndex;
    final isPreDelivery =
        status.index < OrderStatus.assigned.index &&
        status != OrderStatus.completed;

    if (isPreDelivery) {
      return Row(
        children: [
          Icon(Icons.store_outlined, size: 14, color: status.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Kitchen: ${status.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: compact ? 36 : 48,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: EdgeInsets.only(bottom: compact ? 14 : 18),
                  color: i <= currentIndex
                      ? steps[i].color.withValues(alpha: 0.5)
                      : Colors.grey.shade200,
                ),
              ),
            _TimelineNode(
              step: steps[i],
              isComplete: i < currentIndex,
              isCurrent: i == currentIndex,
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final OrderStatus step;
  final bool isComplete;
  final bool isCurrent;
  final bool compact;

  const _TimelineNode({
    required this.step,
    required this.isComplete,
    required this.isCurrent,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final active = isComplete || isCurrent;
    final color = active ? step.color : Colors.grey.shade300;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: compact ? 22 : 28,
          height: compact ? 22 : 28,
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.15)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            isComplete ? Icons.check_rounded : step.icon,
            size: compact ? 12 : 14,
            color: active ? color : Colors.grey.shade400,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 52,
            child: Text(
              step.label.split(' ').first,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                color: active ? color : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class OrderStatusChipBar extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const OrderStatusChipBar({
    super.key,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = selected == option;
          final status = option == 'All'
              ? null
              : OrderStatus.fromString(option);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(option),
              selected: isSelected,
              showCheckmark: false,
              avatar: status != null
                  ? Icon(status.icon, size: 16, color: status.color)
                  : null,
              selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF2E7D32),
              labelStyle: GoogleFonts.lato(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                fontSize: 13,
              ),
              onSelected: (_) => onSelected(option),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class OrderPanelDecoration {
  static BoxDecoration card({Color? borderColor}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? const Color(0xFFE8ECE8)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
