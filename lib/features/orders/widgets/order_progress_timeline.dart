import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../data/models/order_models.dart';

/// Timeline horizontale de suivi commande — 7 étapes style Uber Eats / Deliveroo.
///
/// Étapes :
///   1. Reçue        (pending)
///   2. Acceptée     (confirmed — paiement validé)
///   3. En préparation (preparing)
///   4. Prête        (ready / assigned)
///   5. Récupérée    (pickedUp)
///   6. En route     (delivering / arrivedClient)
///   7. Livrée       (delivered)
///
/// Mapping basé sur l'enum Flutter `OrderStatus`. Quand le backend enverra un
/// `delivery.status` distinct, remplacer [_progressFor] par la règle exacte.
class OrderProgressTimeline extends StatefulWidget {
  final OrderStatus status;

  /// Horodatages par étape (index 0..6). `null` = non franchie / inconnue.
  final List<DateTime?> stepTimestamps;

  const OrderProgressTimeline({
    super.key,
    required this.status,
    this.stepTimestamps = const [null, null, null, null, null, null, null],
  });

  @override
  State<OrderProgressTimeline> createState() => _OrderProgressTimelineState();
}

class _OrderProgressTimelineState extends State<OrderProgressTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  static const List<String> _labels = [
    'Reçue',
    'Acceptée',
    'En\npréparation',
    'Prête',
    'Récupérée',
    'En\nroute',
    'Livrée',
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int _progressFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return 7;
      case OrderStatus.delivering:
        return 6;
      case OrderStatus.pickedUp:
        return 5;
      case OrderStatus.ready:
      case OrderStatus.assigned:
        return 4;
      case OrderStatus.preparing:
        return 3;
      case OrderStatus.confirmed:
        return 2;
      case OrderStatus.pending:
        return 1;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progressFor(widget.status);
    final cancelled = progress == -1;
    final activeIdx = cancelled ? -1 : progress - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (i) {
        final reached = !cancelled && i < activeIdx;
        final isActive = !cancelled && i == activeIdx;

        // Le segment qui arrive sur ce dot (côté gauche).
        final leftSegmentDone = !cancelled && i > 0 && i <= activeIdx;
        // Le segment qui part de ce dot (côté droit).
        final rightSegmentDone = !cancelled && i < activeIdx;
        // Segment animé : part de l'étape active vers la suivante.
        final rightSegmentAnimated = isActive && i < 6;

        final ts = widget.stepTimestamps[i];

        return Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    Expanded(
                      child: i == 0
                          ? const SizedBox.shrink()
                          : _Segment(
                              done: leftSegmentDone,
                              cancelled: cancelled,
                              animated: false,
                              pulse: _pulse,
                            ),
                    ),
                    _Dot(
                      reached: reached,
                      active: isActive,
                      cancelled: cancelled,
                      pulse: _pulse,
                    ),
                    Expanded(
                      child: i == 6
                          ? const SizedBox.shrink()
                          : _Segment(
                              done: rightSegmentDone,
                              cancelled: cancelled,
                              animated: rightSegmentAnimated,
                              pulse: _pulse,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: (reached || isActive)
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: cancelled
                        ? AppColors.textTertiary
                        : (reached || isActive)
                            ? AppColors.charcoal
                            : AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 14,
                child: ts != null && !cancelled
                    ? Text(
                        DateFormat('HH:mm').format(ts.toLocal()),
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Dot ─────────────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final bool reached;
  final bool active;
  final bool cancelled;
  final AnimationController pulse;

  const _Dot({
    required this.reached,
    required this.active,
    required this.cancelled,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    const grey = Color(0xFFE0E0E0);

    if (active && !cancelled) {
      return AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          final v = pulse.value;
          return SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 20 + v * 8,
                  height: 20 + v * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        AppColors.primary.withValues(alpha: 0.25 * (1 - v)),
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (reached && !cancelled) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
        child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
      );
    }

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(color: grey, width: 2),
      ),
    );
  }
}

// ─── Segment (connector) ─────────────────────────────────────────────────────

class _Segment extends StatelessWidget {
  final bool done;
  final bool cancelled;
  final bool animated;
  final AnimationController pulse;

  const _Segment({
    required this.done,
    required this.cancelled,
    required this.animated,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    if (animated && !cancelled) {
      return AnimatedBuilder(
        animation: pulse,
        builder: (_, __) => CustomPaint(
          painter: _AnimatedBarPainter(progress: pulse.value),
          size: const Size(double.infinity, 3),
        ),
      );
    }
    if (done && !cancelled) {
      return Container(
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }
    return CustomPaint(
      painter: _DashedBarPainter(
        color: cancelled ? const Color(0xFFCFCFCF) : const Color(0xFFE0E0E0),
      ),
      size: const Size(double.infinity, 3),
    );
  }
}

class _DashedBarPainter extends CustomPainter {
  final Color color;

  _DashedBarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBarPainter old) => old.color != color;
}

class _AnimatedBarPainter extends CustomPainter {
  final double progress;

  _AnimatedBarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;

    final bg = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), bg);

    final fg = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(size.width * progress, y), fg);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBarPainter old) =>
      old.progress != progress;
}
